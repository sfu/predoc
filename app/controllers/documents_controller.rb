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

    # Convert the source file unless a cached conversion already exists. The cached file has the same name as the
    # hash of its original contents.
    #
    # NOTE: The file is first converted in the working directory and then moved to the cache, because this will keep
    # the temporary "LibreOffice" directory in one single place.
    unless FileTest::exists?(cached_path)
      # save a temporary copy of the source file
      File.open(temp_path, 'wb') do |f|
        f.write response.body
      end

      # TODO: detect whether conversion is needed/possible (filter MIME types?)

      # use Docsplit to create the PDF version of the source file
      Docsplit.extract_pdf(temp_path, :output => get_working_directory)

      # delete the temporary source file
      File::delete(temp_path)

      # test whether conversion was successful (created a file)
      unless FileTest::exists?(converted_path)
        # file conversion failed; render the error page instead
        render :action => :error, :locals => { :error => 'File cannot be converted', :source => @source }
        return
      end

      # move the converted file into the cache
      FileUtils::move(converted_path, cached_path)
    end

    # TODO: do we need to enable CORS?
    #response.headers["Access-Control-Allow-Origin"] = "http://localhost"

    # output the converted file
    send_file cached_path, :type => 'application/pdf', :disposition => 'inline'
  end

end
