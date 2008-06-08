module MythTV

  class Recording
    # Represents a recording that is held on the MythTV Backend server we are communicating with.
    #
    # The keys included here, and the order in which they are specified seem to change between protocol version bumps
    # on the MythTV backend, so this array affects both the initialize() and to_s() methods.
    #
    # Found inside mythtv/libs/libmythtv/programinfo.cpp in the MythTV subversion repository
    RECORDINGS_ELEMENTS = [ :title, :subtitle, :description, :category, :chanid, :chanstr, :chansign, :channame,
                            :pathname, :filesize_hi, :filesize_lo, :startts, :endts, :duplicate, :shareable, :findid,
                            :hostname, :sourceid, :cardid, :inputid, :recpriority, :recstatus, :recordid, :rectype,
                            :dupin, :dupmethod, :recstartts, :recendts, :repeat, :programflags, :recgroup, :chancommfree,
                            :chanOutputFilters, :seriesid, :programid, :lastmodified, :stars, :originalAirDate,
                            :hasAirDate, :playgroup, :recpriority2, :parentid, :storagegroup, :audioproperties,
                            :videoproperties, :subtitleType ]
    
    # Warning, metaprogramming ahead: Create attr_accessors for each symbol defined in MythTVRecording::RECORDINGS_ELEMENTS
    def initialize(recording_array)
      class << self;self;end.class_eval { RECORDINGS_ELEMENTS.each { |field| attr_accessor field } }
      
      RECORDINGS_ELEMENTS.each_with_index do |field, i|
        send(field.to_s + '=', recording_array[i])
      end
    end
  
    # A string representation of a Recording is used when we converse with the MythTV Backend about that recording
    def to_s
      RECORDINGS_ELEMENTS.collect { |field| self.send(field.to_s) }.join(MythTV::Backend::FIELD_SEPARATOR) + MythTV::Backend::FIELD_SEPARATOR
    end
    
    # Convenience methods to access the start and end times as Time objects, and duration as an Float
    def start;  Time.at(recstartts.to_i); end
    def end;  Time.at(recendts.to_i); end
    def duration; self.end - self.start; end
  
    # Cribbed from the Mythweb PHP code. Required for some method calls to the backend
    def myth_delimited_recstart;  myth_format_time(recstartts, :delimited); end
  
    # Formats the start time for use in the copy process, as the latter half of the filename is a non-delimited time string
    def myth_nondelimited_recstart; myth_format_time(recstartts, :nondelimited);  end
    
    # Convert the lo/hi long representation of the filesize into a string
    def filesize
      [filesize_lo.to_i, filesize_hi.to_i].pack("ll").unpack("Q").to_s
    end
    
    # Fetch the path section of the pathname
    def path;  URI.parse(pathname).path; end
    
    # Strip the filename out from the path returned by the server
    def filename;  File.basename(URI.parse(pathname).path); end
  
    private
  
    def myth_format_time(timestamp, format = :nondelimited)
      timestamp = timestamp.to_i if timestamp.class != Bignum
      case format
      when :nondelimited
        Time.at(timestamp).strftime("%Y%m%d%H%M%S")
      when :delimited
        Time.at(timestamp).strftime("%Y-%m-%dT%H:%M:%S")
      end
    end
      
  end # end Recording
end # end MythTV