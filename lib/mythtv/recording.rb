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
                            :videoproperties, :subtitleType, :year ]
    
    # Map the numeric 'recstatus' field to a status message.
    # Extracted from libmythtv/programinfo.h
    RECSTATUS_MAP = { -9 => :rsFailed,
                      -8 => :rsTunerBusy,
                      -7 => :rsLowDiskSpace,
                      -6 => :rsCancelled,
                      -5 => :rsMissed,
                      -4 => :rsAborted,
                      -3 => :rsRecorded,
                      -2 => :rsRecording,
                      -1 => :rsWillRecord,
                       0 => :rsUnknown,
                       1 => :rsDontRecord,
                       2 => :rsPreviousRecording,
                       3 => :rsCurrentRecording,
                       4 => :rsEarlierShowing,
                       5 => :rsTooManyRecordings,
                       6 => :rsNotListed,
                       7 => :rsConflict,
                       8 => :rsLaterShowing,
                       9 => :rsRepeat,
                      10 => :rsInactive,
                      11 => :rsNeverRecord,
                      12 => :rsOffLine,
                      13 => :rsOtherShowing }

    # Warning, metaprogramming ahead: Create attr_accessors for each symbol defined in MythTVRecording::RECORDINGS_ELEMENTS
    def initialize(recording_array, options = {})
      
      default_options = { :protocol_version => MythTV::DEFAULT_PROTOCOL_VERSION }
      options = default_options.merge(options)
      
      # Find out how many of the recording elements we use for this protocol version
      unless mapping = MythTV::PROTOCOL_MAPPING.find { |m| m[:protocol_version] == options[:protocol_version] }
        raise MythTV::ProtocolError, "Unable to find definition of protocol version #{options[:protocol_version]} in MythTV::PROTOCOL_MAPPING"
      end
      
      # Slice the RECORDINGS_ELEMENTS array according to how many we require for this protocol version
      elements_for_protocol_version = RECORDINGS_ELEMENTS.slice(0, mapping[:recording_elements])
      
      self.class.class_eval { elements_for_protocol_version.each { |field| attr_accessor field } }
      
      elements_for_protocol_version.each_with_index do |field, i|
        send("#{field}=", recording_array[i])
      end
      
      @elements_for_protocol_version = elements_for_protocol_version
    end
    
    
    # A string representation of a Recording is used when we converse with the MythTV Backend about that recording
    def to_s
      @elements_for_protocol_version.collect do |field|
        self.send(field.to_s) 
      end.join(MythTV::Backend::FIELD_SEPARATOR) + MythTV::Backend::FIELD_SEPARATOR
    end
    
    # Convenience methods to access the start and end times as Time objects, and duration as an Float
    def start;  Time.at(recstartts.to_i); end
    def end;  Time.at(recendts.to_i); end
    def duration; self.end - self.start; end
    
    # Convert the status number into a symbol via our map
    def recstatus_sym; RECSTATUS_MAP[recstatus.to_i]; end
    
    # Cribbed from the Mythweb PHP code. Required for some method calls to the backend
    def myth_delimited_recstart;  MythTV::Utils.format_time(recstartts, :delimited); end
  
    # Formats the start time for use in the copy process, as the latter half of the filename is a non-delimited time string
    def myth_nondelimited_recstart; MythTV::Utils.format_time(recstartts, :nondelimited);  end
    
    # Convert the lo/hi long representation of the filesize into a string
    def filesize
      [filesize_lo.to_i, filesize_hi.to_i].pack("ll").unpack("Q").to_s
    end
    
    # Fetch the path section of the pathname
    def path;  URI.parse(pathname).path; end
    
    # Strip the filename out from the path returned by the server
    def filename;  File.basename(URI.parse(pathname).path); end
  
  end # end Recording
end # end MythTV