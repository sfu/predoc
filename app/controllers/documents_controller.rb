require 'net/https'
require 'docsplit'
require 'digest/sha1'

class DocumentsController < ApplicationController

  def view
    # TODO: add page controls, and maybe pdf.js?

    # get the source file URL
    @source = params[:source]
  end

  def get_storage_directory
    storage_directory = "#{Rails.root}/tmp/doctor"

    # create storage directory unless already exists
    unless FileTest::directory?(storage_directory)
      Dir::mkdir(storage_directory)
    end

    storage_directory
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

    # prepare storage directory and file parameters
    storage_directory = get_storage_directory
    file_name = generate_hash response.body
    file_path = "#{storage_directory}/#{file_name}"
    converted_file_path = "#{file_path}.pdf"

    # TODO: (security considerations) if there is ever a collision in the hash,
    # someone will see the preview of a different (potentially someone else's) file

    # Convert the source file unless a cached conversion already exists.
    #
    # NOTE: A source document is deemed to have a cached copy if there is a converted document
    # whose filename matches the hash of its contents.
    unless FileTest::exists?(converted_file_path)
      # save a temporary copy of the source file
      File.open(file_path, 'wb') do |f|
        f.write response.body
      end

      # TODO: detect whether conversion is needed/possible (filter MIME types?)

      # use Docsplit to create the PDF version of the source file
      Docsplit.extract_pdf(file_path, :output => storage_directory)

      # delete the temporary source file
      File::delete(file_path)
    end

    # TODO: do we need to enable CORS?
    #response.headers["Access-Control-Allow-Origin"] = "http://localhost"

    # output the converted file
    send_file converted_file_path, :type => 'application/pdf', :disposition => 'inline'
  end

end
