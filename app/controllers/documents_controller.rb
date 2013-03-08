require 'net/https'
require 'docsplit'

class DocumentsController < ApplicationController

  def view
    # TODO: add page controls, and maybe pdf.js?

    # get the source file URL
    @source = params[:source]
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
    temp_filename = '_doctor_temp'

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

    # save a copy of the source file
    File.open("#{Rails.root}/tmp/#{temp_filename}", 'wb') do |f|
      f.write response.body
    end

    # TODO: detect whether conversion is needed/possible (filter MIME types?)

    # use Docsplit to create the PDF version of the source file
    Docsplit.extract_pdf("#{Rails.root}/tmp/#{temp_filename}", :output => "#{Rails.root}/tmp")

    # TODO: do we need to enable CORS?
    #response.headers["Access-Control-Allow-Origin"] = "http://localhost"

    # output the converted file
    send_file "#{Rails.root}/tmp/#{temp_filename}.pdf", :type => 'application/pdf', :disposition => 'inline'
  end

end
