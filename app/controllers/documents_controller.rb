require 'net/https'

class DocumentsController < ApplicationController

  def view
    # get the source URL
    @source = params[:source]

    # set up HTTP the request
    uri = URI.parse(@source)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)

    # send the request and read the response
    response = http.request(request)

    File.open("#{Rails.root}/tmp/doctor_temp", 'wb') do |f|
      f.write response.body
    end

    %x( /Applications/LibreOffice.app/Contents/MacOS/soffice --headless --convert-to pdf --outdir #{Rails.root}/tmp #{Rails.root}/tmp/doctor_temp )

    # output the file
    send_file "#{Rails.root}/tmp/doctor_temp.pdf", :type => 'application/pdf', :disposition => 'inline'
  end

end
