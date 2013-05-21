require 'net/https'
require 'docsplit'
require 'digest/sha1'

class DocumentsController < ApplicationController

  def view
    # TODO: add page controls, and maybe pdf.js?

    # get the source file URL
    @source = params[:source]
  end

  def get_cache_directory(hash)
    # construct a nested directory structure using the first two characters of the hash
    # e.g. b12f9a33c5afa6fe98286465a5c453c1898d07f7 will be stored in {root}/b/1
    hash_chars = hash.split('')
    cache_directory = "#{Predoc::Config::CACHE_ROOT_DIRECTORY}/#{hash_chars[0]}/#{hash_chars[1]}"

    # create directory unless already exists
    unless FileTest::directory?(cache_directory)
      FileUtils::makedirs(cache_directory)
    end

    cache_directory
  end

  def get_temp_path(hash)
    # create directory unless already exists
    working_directory = "#{Predoc::Config::WORKING_DIRECTORY}"
    unless FileTest::directory?(working_directory)
      FileUtils::makedirs(working_directory)
    end

    # There will be times when the same file is requested by multiple users in a short period of time. If we use the
    # same temp file, some requests will fail because the temp file is deleted midway by another request. The time hash
    # is based on the current time, and adds reasonable uniqueness to each request.
    # NOTE: the time hash is truncated to keep the file name length manageable
    time_hash = (Digest::SHA1.hexdigest Time.now.to_f.to_s)[0, 8]

    "#{working_directory}/#{hash}-#{time_hash}"
  end

  def generate_hash(content)
    Digest::SHA1.hexdigest content
  end

  def read_mime_type(path)
    # read the file MIME type using the `file` command
    # NOTE: We are intentionally ignoring any errors (and returning nil) because even if the file type is unknown, we
    # will still attempt to process the file.
    IO.popen(['file', '--brief', '--mime-type', path]).read.chomp rescue nil
  end

  def send_pdf(path)
    send_file path, :type => 'application/pdf', :disposition => 'inline'
  end

  def fetch(uri_string, limit = 10)
    # prevent redirect loops
    raise StandardError, 'Too many redirects' if limit == 0

    # set up HTTP the request
    uri = URI.parse(uri_string)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme.downcase == 'https'
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)

    # send the request and read the response
    response = http.request(request)

    # return the response (or follow the redirect)
    case response
    when Net::HTTPSuccess then response
    when Net::HTTPRedirection then fetch(response['location'], limit - 1)
    else response.error!
    end
  end

  def convert
    # TODO: do we need to enable CORS?
    #response.headers["Access-Control-Allow-Origin"] = "http://localhost"

    # get the source file URL
    @source = params[:source]

    # read the source file to be converted
    begin
      response = fetch(@source, 10)
    rescue Exception => e
      # error occurred; render the error page instead
      render :action => :error, :locals => { :error => e.to_s, :source => @source }
      return
    end

    # prepare directory and file paths
    hash = generate_hash response.body
    cache_directory = get_cache_directory hash
    temp_path = get_temp_path hash
    converted_path = "#{temp_path}.pdf"
    cached_path = "#{cache_directory}/#{hash}.pdf"

    # If a cached conversion already exists, output it immediately. The cached file has the same name as the hash of its
    # original contents.
    if FileTest::exists?(cached_path)
      send_pdf cached_path
      return
    end
    # TODO: consider security implications of using the hash to cache files (e.g. what happens if a collision occurs?)

    # save a temporary copy of the source file
    File.open(temp_path, 'wb') do |f|
      f.write response.body
    end

    # If the source file is already a PDF, no conversion is needed. Just save it into cache and output it immediately.
    mime_type = read_mime_type temp_path
    if mime_type == 'application/pdf'
      FileUtils::move(temp_path, cached_path)
      send_pdf cached_path
      return
    end
    # REVIEW: Should we preemptively blacklist certain incompatible MIME types so we can avoid unnecessary conversion?

    begin
      # create the PDF version of the source file
      Docsplit.extract_pdf(temp_path, :output => Predoc::Config::WORKING_DIRECTORY)
    rescue Docsplit::ExtractionFailed
      # This exception is thrown when the extraction exited with a non-zero status. This is handled later because the
      # conversion would not have yielded a file. Do nothing now.
    end

    # the source file is no longer needed
    File::delete(temp_path)

    # test whether conversion yielded a file
    unless FileTest::exists?(converted_path)
      # missing converted file; render the error page instead
      render :action => :error, :locals => { :error => 'Preview failed to be created', :source => @source }
      return
    end

    # save the converted file to cache and output it
    FileUtils::move(converted_path, cached_path)
    send_pdf cached_path
  end

end
