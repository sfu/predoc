require 'net/https'
require 'docsplit'
require 'digest/sha1'

class DocumentsController < ApplicationController

  def view
    # TODO: add page controls, and maybe pdf.js?

    # get the source file URL
    @source = params[:source]
  end

  def get_working_directory
    "#{Rails.root}/tmp/predoc"
  end

  def get_cache_directory(hash)
    # construct a nested directory structure using the first two characters of the hash
    # e.g. b12f9a33c5afa6fe98286465a5c453c1898d07f7 will be stored in {root}/b/1
    hash_chars = hash.split('')
    cache_directory = "#{get_working_directory}/#{hash_chars[0]}/#{hash_chars[1]}"

    # create directory unless already exists
    unless FileTest::directory?(cache_directory)
      FileUtils::makedirs(cache_directory)
    end

    cache_directory
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
    temp_path = "#{get_working_directory}/#{hash}"
    converted_path = "#{temp_path}.pdf"
    cached_path = "#{cache_directory}/#{hash}.pdf"

    # TODO: (security considerations) if there is ever a collision in the hash,
    # someone will see the preview of a different (potentially someone else's) file

    # If a cached conversion already exists, output it immediately. The cached file has the same name as the hash of its
    # original contents.
    if FileTest::exists?(cached_path)
      send_pdf cached_path
      return
    end

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
      # use Docsplit to create the PDF version of the source file
      Docsplit.extract_pdf(temp_path, :output => get_working_directory)
    rescue Docsplit::ExtractionFailed
      # TODO: consider combining this with the FileTest::exists? check below...
      # file conversion failed; render the error page instead
      render :action => :error, :locals => { :error => 'Preview cannot be created from source', :source => @source }
      return
    end

    # delete the temporary source file
    File::delete(temp_path)

    # test whether conversion yielded a file
    unless FileTest::exists?(converted_path)
      # missing converted file; render the error page instead
      render :action => :error, :locals => { :error => 'Preview was not created properly', :source => @source }
      return
    end

    # move the converted file into the cache
    FileUtils::move(converted_path, cached_path)

    # output the converted file
    send_pdf cached_path
  end

end
