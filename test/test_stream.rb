require 'rubygems'
require 'mongrel'
require 'open3'

require '../lib/ruby-mythtv'

require 'pp'

# A test class for looking at ways to stream mythtv recordings through ffmpeg, and out to an HTTP client
# This is just kept here for reference purposes, and is not integrated into the test suite
class StreamFileHandler < Mongrel::HttpHandler

  def process(request, response)
    pp "request.params => #{request.params['REQUEST_PATH']}"
    response.write("HTTP/1.1 200 OK\r\n")
    response.write("Accept-Ranges: bytes\r\n")
    response.write("Content-Length: 999999999\r\n")
    response.write("Keep-Alive: timeout=5, max=100\r\n")
    response.write("Connection: Keep-Alive\r\n")
    response.write("Content-type: video/mpeg\r\n\r\n")
    
    buffer=""
    total_bytes_read = 0
    
    File.open("/Users/nick/Sites/0_replex.mpeg", "r") do |f|
      while data = f.read(65535)
        response.write(data)
        printf "."
        total_bytes_read += data.length
      end
    end

    puts "Closing connection. Wrote #{total_bytes_read} bytes"
    response.done
  end
end



class StreamHandler < Mongrel::HttpHandler

  def get_recording(recording_id = 0)
    @backend = MythTV::Backend.new(:host => '192.168.1.10')
    all_recordings = @backend.query_recordings
    all_recordings[recording_id]
  end
  
  def process(request, response)
    puts "request.params => #{request.params['REQUEST_PATH']}"
    
    if url_match = /\/(\d+)$/.match(request.params['REQUEST_PATH'])
      recording_id = url_match[1].to_i
      puts "Parsed URI: recording_id is #{recording_id}"
    else
      # Default to picking the latest recording
      puts "Could not parse URI: Defaulting to recording_id 0"
      recording_id = 0
    end
    
    recording = get_recording(recording_id)

    response.status = 200
    response.send_status(nil)

    response.header['Content-Type'] = "video/x-flv"
    response.header['Connection'] = "Close"
    
    #response.header['Content-Length'] = 999999999
    #response.header['ETag'] = "74c1a8-199fe66-44dc5c7"
    #response.header['Keep-Alive'] = "timeout=5, max=100"

    # Don't know this now. Unless we can guess at TS->PS size conversion
    #response.header['Content-Length'] = 999999999
    
    response.send_header
    buffer=""
    @backend.stream(recording) do |data|
      
      buffer += data
      if buffer.length > 262140
        response.write(buffer)
      end
      
      
      #response.write(buff)
    end

    puts "Closing backend connection"
    @backend.close
    response.done
  end
end

class StreamTranscodeHandler < Mongrel::HttpHandler
  
  REPLEX_CMD = "/opt/local/bin/replex -o /dev/stdout -i TS -v %s -a %s -t MPEG2 /dev/stdin"
  FFMPEG_CMD = "/opt/local/bin/ffmpeg -i - -ac 1 -ar 22050 -ab 32000 -r 12.5 -f flv -s 320x240 -b 800k -"
  DSVIDEO_CMD = "/Users/nick/Work/NDS/DSVideo/releases/dsvideo-1.01/encoder/dsvideo32 -s -o /dev/stderr"
  
  def get_recording(recording_id = 0)
    @backend = MythTV::Backend.new(:host => 'pico')
    all_recordings = @backend.query_recordings
    all_recordings[recording_id]
  end
  
  def process(request, response)
    @pids = []
    
    puts "request.params => #{request.params['REQUEST_PATH']}"
    
    if url_match = /\/(\d+)$/.match(request.params['REQUEST_PATH'])
      recording_id = url_match[1].to_i
      puts "Parsed URI: recording_id is #{recording_id}"
    else
      # Default to picking the latest recording
      puts "Could not parse URI: Defaulting to recording_id 0"
      recording_id = 0
    end
    
    recording = get_recording(recording_id)

    response.status = 200
    response.send_status(nil)
    response.header['Content-Type'] = "video/x-flv"
    response.header['Connection'] = "close"
    response.send_header

    # response.write("HTTP/1.1 200 OK\r\n")
    # response.write("Cache-Control: no-cache\r\n")
    # response.write("Pragma: no-cache\r\n")
    # response.write("Accept-Ranges: bytes\r\n")
    # response.write("Content-Length: 999999999\r\n")
    # response.write("Keep-Alive: timeout=5, max=100\r\n")
    # response.write("Connection: Keep-Alive\r\n")
    # response.write("Content-type: video/mpeg\r\n\r\n")
    
    # Find PIDs
    #@stream_sample = ""
    #@backend.stream(recording, 65535) do |data|
    #  @stream_sample << data
    #end
    
    # puts "Starting auto PID detect"
    #     i=0
    #     pid_counts = Hash.new(0)
    #     while i < (@stream_sample.length - 188) do
    #       if @stream_sample[i] == 0x47 &&
    #          @stream_sample[i+188] == 0x47
    #          
    #          upper_byte = @stream_sample[i+1] << 8
    #          lower_byte = @stream_sample[i+2]
    #          pid = (upper_byte|lower_byte) & 0x1fff
    #          pid_counts[pid] += 1
    #          i += 188
    #       else
    #         i += 1
    #       end
    #     end
    
    #puts pid_counts.inspect
    #pid_counts = pid_counts.sort { |a,b| b[1] <=> a[1] }
    #video_pid = pid_counts[0][0]
    #puts "Video PID should be #{video_pid}"
    
    #Open3.popen3(DSVIDEO_CMD) do |stdin, stdout, stderr|
    Open3.popen3(FFMPEG_CMD) do |stdin, stdout, stderr|
    #Open3.popen3(REPLEX_CMD % [video_pid, video_pid+1]) do |stdin, stdout, stderr|
      
      Thread.new do
        total_bytes_in = 0
        i = 0
        @backend.stream(recording) do |data|
          #puts "Reading #{data.length}"

          # if total_bytes_in == 0
          #   puts "Looking for start of TS"
          #   while i < (data.length - 188) do
          #     if data[i] == 0x47 && data[i+188] == 0x47
          #       data.slice!(i, -1)
          #       break
          #     else
          #       i += 1
          #     end
          #   end
          # end
          
          stdin.write(data)
          total_bytes_in += data.length
          
          #puts "Read #{total_bytes_in} from MythTV"
          #puts "Wrote #{data.length} bytes to replex stdin"
        end
        
        puts "Just before Thread stdin close"
        stdin.close
      end

      buffer = ""
      total_bytes_out = 0

      #$stdout.sync=(true) if not $stdout.sync
      
      while (resp = stdout.read(65535))
      #while (resp = stderr.read(4096))
        #puts "Writing #{resp.length} to #{response}"
        
        response.write(resp)
        total_bytes_out += resp.length
        #putc('.')
        
        #puts "Wrote #{total_bytes_out} to client"
        #puts "Wrote #{resp.length} bytes to HTTP stream"
      end
      
      while (resp = stderr.read(65535))
        puts resp
      end
      
      puts "At end of popen3"
    end

    puts "Closing backend connection"
    @backend.close
    response.done
  end
end

Mongrel::Configurator.new do
  listener :port => 80 do
    uri "/files/", :handler => StreamFileHandler.new
    uri "/transcodings/", :handler => StreamTranscodeHandler.new
    uri "/recordings/", :handler => StreamHandler.new
  end
  run; join
end