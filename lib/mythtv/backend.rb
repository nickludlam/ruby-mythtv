require 'socket'
require 'uri'
require 'net/http'

module MythTV

  # Raised when we get a response that isn't what we expect
  class CommunicationError < RuntimeError
  end
  
  # Raised when we have a protocol version mismatch
  class ProcolError < RuntimeError
  end
  
  # Raised when a method is passed incomplete initialisation information
  class ArgumentError < RuntimeError
  end
  
  class Backend
    include Socket::Constants
  
    # Our current protocol implementation. TODO: Consider how we support
    # multiple protocol versions within a single gem. In theory this is
    # just a case of limiting the number of attr_accessors that are
    # class_eval'd onto MythTV::Recording, and bumping the number below
    MYTHTV_PROTO_VERSION = 40
    
    # The currently defined field separator in responses
    FIELD_SEPARATOR = "[]:[]"
    
    # The payload size we request from the backend when performing a filetransfer
    TRANSFER_BLOCKSIZE = 65535

    attr_reader :host,
                :port,
                :status_port,
                :connection_type,
                :filetransfer_port,
                :filetransfer_size,
                :socket

    # Open the socket, make a protocol check, and announce we'd like an interactive
    # session with the backend server
    def initialize(options = {})
      default_options = { :port => 6543, :status_port => 6544, :connection_type => :playback }
      options = default_options.merge(options)
      
      raise ArgumentError, "You must specify a :host key and value to initialize()" unless options.has_key?(:host)
      
      @host = options[:host]
      @port = options[:port]
      @status_port = options[:status_port]

      @socket = TCPSocket.new(@host, @port)
      
      check_proto
      
      if options[:connection_type] == :playback
        announce_playback()
      elsif options[:connection_type] == :filetransfer
        announce_filetransfer(options[:filename])
      else
        raise ArgumentError, "Unknown connection type '#{options[:connection_type]}'"
      end
    end

    ############################################################################
    # COMMAND WRAPPERS #########################################################

    # Tell the backend we speak a specific version of the protocol. Raise
    # an error if the backend does not accept that version.
    def check_proto
      send("MYTH_PROTO_VERSION #{MYTHTV_PROTO_VERSION}")
      response = recv
      unless response[0] == "ACCEPT" && response[1] == MYTHTV_PROTO_VERSION.to_s
        close
        raise ProcolError, response.join(": ")
      end
    end

    # Announce ourselves as a Playback connection.
    # http://www.mythtv.org/wiki/index.php/Myth_Protocol_Command_ANN for details
    def announce_playback
      client_hostname = Socket.gethostname
      
      # We don't want to receive broadcast events for this connection
      want_events = "0"
      
      send("ANN Playback #{client_hostname} #{want_events}")
      response = recv

      unless response[0] == "OK"
        close
        raise CommunicationError, response.join(": ")
      else
        @connection_type = :playback  # Not currently used, but may be in later versions
      end
    end

    # Announce ourselves as a FileTransfer connection.
    # http://www.mythtv.org/wiki/index.php/Myth_Protocol_Command_ANN for details
    def announce_filetransfer(filename = nil)
      raise ArgumentError, "you must specify a filename" if filename.nil?
      
      client_hostname = Socket.gethostname
  
      filename = "/" + filename if filename[0] != "/"  # Ensure leading slash
  
      send("ANN FileTransfer #{client_hostname}#{FIELD_SEPARATOR}#{filename}")
      response = recv
  
      # Should get back something like:
      #   OK[]:[]<socket number>[]:[]<file size high 32 bits>[]:[]<file size low 32 bits>
      unless response[0] == "OK"
        close
        raise CommunicationError, response.join(": ")
      else
        @filetransfer_port = response[1]
        @filetransfer_size = [response[3].to_i, response[2].to_i].pack("ll").unpack("Q")[0]
        @connection_type = :filetransfer   # Not currently used, but may be in later versions
      end
    end

    # Simple method to query the load of the backend server. Returns a hash with keys for
    # :one_minute, :five_minute and :fifteen_minute
    def query_load
      send("QUERY_LOAD")
      response = recv
      { :one_minute => response[0].to_f, :five_minute => response[1].to_f, :fifteen_minute => response[2].to_f }
    end

    # List all recordings stored on the backend. You can filter via the storagegroup property,
    # and this defaults to /Default/, to list the recordings, rather than any which are from
    # LiveTV sessions.
    # 
    # Returns an array of MythTV::Recording objects
    def query_recordings(options = {})
      default_options = { :filter => { :storagegroup => /Default/ } }
      options = default_options.merge(options)
      
      send("QUERY_RECORDINGS Play")
      response = recv

      recording_count = response.shift.to_i
      recordings = []

      while recording_count > 0
        recording_array = response.slice!(0, Recording::RECORDINGS_ELEMENTS.length)

        recording = Recording.new(recording_array)

        options[:filter].each_pair do |k, v|
          recordings.push(recording) if recording.send(k) =~ v
        end
        
        recording_count -= 1
      end

      recordings = recordings.sort_by { |r| r.startts }
      recordings.reverse!
    end
    
    # This method will return the next free recorder that the backend has available to it
    # TODO: Fix up the checking of response. Does it return an IP or address in element 1?
    def get_next_free_recorder
      send("GET_NEXT_FREE_RECORDER#{FIELD_SEPARATOR}-1")
      response = recv

      # If we have a recorder free, return the recorder id, otherwise false
      response[0] == "-1" ? false : response[0].to_i
    end
    
    # This will trigger the backend to start recording Live TV from a certain channel.
    # TODO: This is currently buggy, so avoid until it's fixed in a later release
    def spawn_live_tv(recorder_id, start_channel = 1)
      client_hostname = Socket.gethostname
      spawn_time = Time.now.strftime("%y-%m-%dT%H:%M:%S")
      chain_id = "livetv-#{client_hostname}-#{spawn_time}"
      
      query_recorder(recorder_id, "SPAWN_LIVETV", [chain_id, 0, "#{start_channel}"])
      response = recv
      
      # If we have an "OK" back, then return the chain_id, otherwise return false
      response[0] == "OK" ? chain_id : false
    end
    
    # This method returns an array of recording objects which describe which programmes
    # are to be recorded as far as the current EPG data extends
    def query_scheduled
      send("QUERY_GETALLSCHEDULED")
      response = recv
      
      recording_count = response.shift.to_i
      recordings = []

      while recording_count > 0
        recording_array = response.slice!(0, Recording::RECORDINGS_ELEMENTS.length)
        recordings << Recording.new(recording_array)
        recording_count -= 1
      end

      recordings = recordings.sort_by { |r| r.startts }
      recordings.reverse!
    end

    # Wrap the QUERY_MEMSTATS backend command. Returns a hash with keys for
    # :used_memory, :free_memory, :total_swap and :free_swap
    def query_memstats
      send("QUERY_MEMSTATS")
      response = recv
      
      # We expect to get back 4 elements only for this method
      raise CommunicationError, "Unexpected response from QUERY_MEMSTATS: #{response.join(":")}" if response.length != 4

      { :used_memory => response[0].to_i, :free_memory => response[1].to_i, :total_swap => response[2].to_i, :free_swap => response[3].to_i }
    end

    # Wrap the QUERY_UPTIME backend command. Return a single integer
    def query_uptime
      send("QUERY_UPTIME")
      response = recv

      # We expect to get back 1 element only for this method
      raise CommunicationError, "Unexpected response from QUERY_UPTIME: #{response.join(":")}" if response.length != 1

      response[0].to_i
    end

    # This is used when transfering files from the backend. It requests that the next block of data
    # be sent to the socket, ready for us to recieve
    def query_filetransfer_transfer_block(sock_num, size)
      query = "QUERY_FILETRANSFER #{sock_num}#{FIELD_SEPARATOR}REQUEST_BLOCK#{FIELD_SEPARATOR}#{size}"
      send(query)
    end
    
    # Tell the backend we've finished talking to it for the current session
    def close
      send("DONE")
      @socket.close unless @socket.nil?
    end
    
    ############################################################################
    # STATUS PORT METHODS
    
    # Returns a string which contains a PNG image of the this recording. The time offset
    # into the file defaults to two minutes, and the default image width is 120 pixels.
    # This uses the separate status port, rather than talking over the backend control port
    def preview_image(recording, options = {})
      default_options = { :height => 120, :secs_in => 120 }
      options = default_options.merge(options)
    
      # Generate our query string for the MythTV request
      query_string = "ChanId=#{recording.chanid}&StartTime=#{recording.myth_delimited_recstart}"

      # Add in the optional parameters if they were specified
      query_string += "&SecsIn=#{options[:secs_in]}" if options[:secs_in]
      query_string += "&Height=#{options[:height]}" if options[:height]
      query_string += "&Width=#{options[:width]}" if options[:width]
    
      url = URI::HTTP.build( { :host  => @host,
                               :port  => @status_port,
                               :path  => "/Myth/GetPreviewImage",
                               :query => query_string } )
      
      # Make a GET request, and store the image data returned
      image_data = Net::HTTP.get(url)

      image_data
    end
    
    ############################################################################
    # FILETRANSFER RELATED METHODS

    # Yield into the given block with the data buffer of size TRANSFER_BLOCKSIZE
    def stream(recording, options = {}, &block)
    
      # Initialise a new connection of connection_type => :filetransfer
      data_conn = Backend.new(:host => @host,
                              :port => @port,
                              :status_port => @status_port,
                              :connection_type => :filetransfer,
                              :filename => recording.path)

      ft_port = data_conn.filetransfer_port
      ft_size = data_conn.filetransfer_size
    
      blocksize = options.has_key?(:transfer_blocksize) ? options[:transfer_blocksize] : TRANSFER_BLOCKSIZE

      total_transfered = 0

      begin
        # While we still have data to fetch
        while total_transfered < ft_size
          # Make a request for the backend to send data
          query_filetransfer_transfer_block(ft_port, blocksize)

          # Collect the socket data in a string
          buffer = ""
       
          while buffer.length < blocksize
            buffer += data_conn.socket.recv(blocksize)
            # Special case for when the remainer to fetch is less than TRANSFER_BLOCKSIZE
            break if total_transfered + buffer.length == ft_size
          end

          # Yield into the given block to allow the user to process as a stream
          yield buffer
       
          total_transfered += buffer.length
       
          # If the user has only asked for a certain amount of data, stop when we hit this
          break if options[:max_length] && total_transfered > options[:max_length]
        end
      ensure
        # We need to close the data connection regardless of what is going on when we yield
        data_conn.close
      end
      
    end
    
    # Download the file to a given location, either with a default filename, or
    # one specified by the caller
    def download(recording, filename = nil)
      
      # If no filename is given, we default to <title>_<recstartts>.<extension>
      if filename.nil?
        filename = recording.title + "_" +
                   recording.myth_nondelimited_recstart + File.extname(recording.filename) 
      end

      File.open(filename, "wb") do |f|
        stream(recording) { |data| f.write(data) }
      end
    end
    
    # TODO: The LiveTV methods are still work-in-progress.
    def start_livetv(channel = 1)
      # If we have a free recorder...
      if recorder_id = get_next_free_recorder
        puts "Got a recorder ID of #{recorder_id}"
        # If we can spawn live tv...
        if chain_id = spawn_live_tv(recorder_id, channel)
          puts "Got a chain ID of #{chain_id}"
          # Send the two backend event messages
          backend_message(["RECORDING_LIST_CHANGE", "empty"])
          puts "Sent RECORDING_LIST_CHANGE"
          backend_message(["LIVETV_CHAIN UPDATE #{chain_id}", "empty"])
          puts "Sent LIVETV_CHAIN UPDATE"
          
          # Find the filename from here...
          query_recorder(recorder_id, "GET_CURRENT_RECORDING")
          cur_rec = recv
          puts "Current recording is:"
          puts cur_rec.inspect
          recording = Recording.new(cur_rec)
        else
          puts "spawn_live_tv returned with false or nil"
          return false
        end
      else
        puts "get_next_free_recorder returned with false or nil"
        return false
      end
    end

    # TODO: Finish this off. Check response?
    def stop_livetv(recorder_id)
      query_recorder(recorder_id, "STOP_LIVETV")
      response = recv
    end
    
    private
    
    # Private method for the generic QUERY_RECORDER command, which itself
    # wraps a number of sub-commands. 
    def query_recorder(recorder_id, sub_command, options = [])
      # place the recorder_id and sub_command strings on the front of options
      # and join with the FIELD_SEPARATOR. This forms the QUERY_RECORDER command
      cmd_string = options.unshift(recorder_id, sub_command)
      send("QUERY_RECORDER #{options.join(FIELD_SEPARATOR)}")
    end

    # Wraps the BACKEND_MESSAGE command, which just sends events to the
    # backend, with no responses provided. Only events expected are
    # RECORDING_LIST_CHANGE, and LIVETV CHAIN_UPDATE
    def backend_message(event_message = [])
      event_message.unshift("BACKEND_MESSAGE")
      send(message.join(FIELD_SEPARATOR))
    end
    
    # Send a message to the MythTV Backend
    def send(message)
      length = sprintf("%-8d", message.length)
      @socket.write("#{length}#{message}")
    end
    
    # Fetch a reply from the MythTV Backend. Automatically splits around the
    # FIELD_SEPARATOR
    def recv
      count = @socket.recv(8).to_i

      # Where we accumulate the response
      response = ""

      # Keep fetching data until we have received the entire response
      while (count > 0) do
        buf = @socket.recv(TRANSFER_BLOCKSIZE)
        response += buf
        count -= buf.length
      end

      response.split(FIELD_SEPARATOR)
    end
    
  end # end Backend
end # end MythTV