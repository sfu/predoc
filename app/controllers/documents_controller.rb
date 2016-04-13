require 'net/https'
require 'docsplit'
require 'digest/sha1'
require 'timeout'

class DocumentsController < ApplicationController

  def view
    # TODO: add page controls (via params[:embedded] == true), and maybe pdf.js?

    # get the source file URL
    @source = params[:url]
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
    # NOTE: Returns nil if exception thrown. The return value could contain error messages (e.g. no such file).
    IO.popen(['file', '--brief', '--mime-type', path]) { |io| io.read.chomp } rescue nil
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

    # Send events to StatsD (if configured to do so)
    if defined?(Predoc::Config::STATSD_HOST) && Predoc::Config::STATSD_HOST
      statsd = Statsd.new Predoc::Config::STATSD_HOST, Predoc::Config::STATSD_PORT
      statsd.namespace = Predoc::Config::STATSD_NAMESPACE
    end

    # get the source file URL
    # @source = params[:url]
    # url encdoe when url Include Chinese
    @source = URI.encode(params[:url].strip)

    # read the source file to be converted
    begin
      logger.info("[Predoc] Request: #{@source}")
      statsd.increment 'request' if statsd
      response = fetch(@source, 10)
    rescue Exception => e
      # error occurred; render the error page instead
      render :action => :error, :locals => { :error => e.to_s, :source => @source }
      logger.error("[Predoc] Cannot read #{@source} due to #{e.class} (#{e.to_s})")
      statsd.increment 'error.unreadable' if statsd
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
      logger.info("[Predoc] Done; Skip conversion, sending from cache #{@source} (#{hash})")
      statsd.increment 'sent.cached' if statsd
      send_pdf cached_path
      return
    end
    # TODO: consider security implications of using the hash to cache files (e.g. what happens if a collision occurs?)

    # save a temporary copy of the source file
    File.open(temp_path, 'wb') do |f|
      f.write response.body
    end

    mime_type = read_mime_type temp_path

    # REVIEW: Preemptively blacklist certain unsupported MIME types so we can avoid unnecessary/fatal conversions

    # Skip any video files. Delete it and render the error page.
    if mime_type.include? 'video'
      File::delete(temp_path)
      render :action => :error, :locals => { :error => "Unsupported file type '#{mime_type}'", :source => @source }
      logger.error("[Predoc] Unsupported file type '#{mime_type}'")
      statsd.increment 'error.unsupported' if statsd
      return
    end

    # If the source file is already a PDF, no conversion is needed. Just save it into cache and output it immediately.
    if mime_type == 'application/pdf'
      FileUtils::move(temp_path, cached_path)
      logger.info("[Predoc] Done; Skip conversion, caching PDF directly #{@source} (#{hash})")
      statsd.increment 'sent.passthru' if statsd
      send_pdf cached_path
      return
    end

    # When converting certain documents (typically ones that are more complicated), the conversion process could hang.
    # In order to prevent this from paralyzing the overall service, we need a timeout. By forking the conversion into
    # its own subprocess, we can easily and cleanly kill everything in the event of a timeout.
    convert_pid = fork do
      # make this process the group leader (necessary for killing all child processes as a group)
      Process.setpgrp
      begin
        # create the PDF version of the source file
        logger.info("[Predoc] Converting #{@source} (#{hash})")
        statsd.increment 'convert' if statsd
        convert_start = Time.now
        Docsplit.extract_pdf(temp_path, :output => Predoc::Config::WORKING_DIRECTORY)
        convert_duration = ((Time.now - convert_start) * 1000).round
        logger.info("[Predoc] Conversion done in #{convert_duration}ms #{@source} (#{hash})")
        statsd.timing 'converted', convert_duration if statsd
      rescue Docsplit::ExtractionFailed
        # This exception is thrown when the extraction exited with a non-zero status. This is handled later because the
        # conversion would not have yielded a file.
        logger.error("[Predoc] Docsplit::ExtractionFailed for #{@source} (#{hash})")
        statsd.increment 'rescue.inconvertible' if statsd
      end
    end

    begin
      # wait for the conversion subprocess to complete -- with a timeout
      Timeout::timeout(Predoc::Config::CONVERSION_TIMEOUT) { Process.wait(convert_pid) }
    rescue Timeout::Error
      # This exception is thrown when the conversion takes too long. Kill the conversion subprocess group (note the
      # negative PID).
      logger.error("[Predoc] Timeout::Error for #{@source} (#{hash})")
      statsd.increment 'rescue.timeout' if statsd
      Process.kill('TERM', -Process.getpgid(convert_pid))
      # make sure we "reap" the terminated child process; we don't want zombies
      Process.wait(convert_pid)
    end

    # the source file is no longer needed
    File::delete(temp_path)

    # test whether conversion yielded a file
    unless FileTest::exists?(converted_path)
      # missing converted file; render the error page instead
      render :action => :error, :locals => { :error => 'Preview failed to be created', :source => @source }
      logger.error("[Predoc] Cannot convert #{@source} (#{hash})")
      statsd.increment 'error.incomplete' if statsd
      return
    end

    # save the converted file to cache and output it
    FileUtils::move(converted_path, cached_path)
    logger.info("[Predoc] Done; Sending converted #{@source} (#{hash})")
    statsd.increment 'sent.converted' if statsd
    send_pdf cached_path
  end

end
