module MythTV
  
  # Map the protocol versions to the number of properties of
  # recording objects
  PROTOCOL_MAPPING = [
    { :protocol_version => 31, :recording_elements => 35 },
    { :protocol_version => 40, :recording_elements => 46 },
    { :protocol_version => 50, :recording_elements => 47 },
    { :protocol_version => 56, :recording_elements => 47 }
  ]
  
  # Set the default protocol version to announce. Should
  # track the latest release
  DEFAULT_PROTOCOL_VERSION = 56
  
  # For DB schema changes, we have a base set of columns for all the classes which correspond
  # to database tables, and then modify them for each new DBSchemaVer, which is stored in the
  # settings table. We start from MythTV version 0.21 as a base (DBSchemaVer 1214).
  
  # Base set of columns from the channels database table
  CHANNEL_BASE_COLUMNS = [ :chanid, :channum, :freqid, :sourceid, :callsign, :name, :icon, :finetune,
                           :videofilters, :xmltvid, :recpriority, :contrast, :brightness, :colour,
                           :hue, :tvformat, :commfree, :visible, :outputfilters, :useonairguide,
                           :mplexid, :serviceid, :atscsrcid, :tmoffset, :atsc_major_chan,
                           :atsc_minor_chan, :last_record, :default_authority, :commmethod ]

  # Base set of columns from the program database table
  PROGRAM_BASE_COLUMNS = [ :chanid, :starttime, :endtime, :title, :subtitle, :description, :category,
                           :category_type, :airdate, :stars, :previouslyshown, :title_pronounce,
                           :stereo, :subtitled, :hdtv, :closecaptioned, :partnumber, :parttotal,
                           :seriesid, :originalairdate, :showtype, :colorcode, :syndicatedepisodenumber,
                           :programid, :manualid, :generic, :listingsource, :first, :last, :audioprop,
                           :subtitletypes, :videoprop ]
                         
  # Base set of columns from the record database table
  RECORDING_SCHEDULE_BASE_COLUMNS = [ :recordid, :type, :chanid, :starttime, :startdate, :endtime, :enddate,
                                      :title, :subtitle, :description, :category, :profile, :recpriority,
                                      :autoexpire, :maxepisodes, :maxnewest, :startoffset, :endoffset,
                                      :recgroup, :dupmethod, :dupin, :station, :seriesid, :programid,
                                      :search, :autotranscode, :autocommflag, :autouserjob1, :autouserjob2,
                                      :autouserjob3, :autouserjob4, :findday, :findtime, :findid, :inactive,
                                      :parentid, :transcoder, :tsdefault, :playgroup, :prefinput, :next_record,
                                      :last_record, :last_delete, :storagegroup, :avg_delay ]
  
  # All of these schema changes are engineered from libmythtv/dbcheck.cpp
  
  # Changes for the MythTV::Channel class
  CHANNEL_SCHEMA_CHANGES = {
    1160 => { :delete => [ :last_record, :default_authority, :commmethod ] },
    1214 => { },
    1223 => { :delete => [ :commfree, :atscsrcid ] }
  }

  # Changes for the MythTV::Program class
  PROGRAM_SCHEMA_CHANGES = { 
    1160 => { :delete => [:audioprop, :subtitletypes, :videoprop] }
  }

  # Changes for the MythTV::RecordingSchedule class
  RECORDING_SCHEDULE_SCHEMA_CHANGES = { }

end