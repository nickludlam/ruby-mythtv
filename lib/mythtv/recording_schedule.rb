module MythTV
  
  class RecordingSchedule

    DATABASE_COLUMNS = [ :recordid, :type, :chanid, :starttime, :startdate, :endtime, :enddate,
                         :title, :subtitle, :description, :category, :profile, :recpriority,
                         :autoexpire, :maxepisodes, :maxnewest, :startoffset, :endoffset,
                         :recgroup, :dupmethod, :dupin, :station, :seriesid, :programid,
                         :search, :autotranscode, :autocommflag, :autouserjob1, :autouserjob2,
                         :autouserjob3, :autouserjob4, :findday, :findtime, :findid, :inactive,
                         :parentid, :transcoder, :tsdefault, :playgroup, :prefinput, :next_record,
                         :last_record, :last_delete, :storagegroup, :avg_delay ]
    
    attr_accessor(*DATABASE_COLUMNS)
    
    # Map the 'type' column to a string
    RECTYPE_MAP = { 0 => :kNotRecording,
                    1 => :kSingleRecord,
                    2 => :kTimeslotRecord,
                    3 => :kChannelRecord,
                    4 => :kAllRecord,
                    5 => :kWeekslotRecord,
                    6 => :kFindOneRecord,
                    7 => :kOverrideRecord,
                    8 => :kDontRecord,
                    9 => :kFindDailyRecord,
                   10 => :kFindWeeklyRecord }
    #
    RECDUPIN_MASK = { :kDupsInRecorded    => 0x01,
                      :kDupsInOldRecorded => 0x02,
                      :kDupsInAll         => 0x0F,
                      :kDupsNewEpi        => 0x10,
                      :kDupsExRepeats     => 0x20,
                      :kDupsExGeneric     => 0x40,
                      :kDupsFirstNew      => 0x80 }
    #
    RECDUPMETHOD_MASK = { :kDupCheckNone        => 0x01,
                          :kDupCheckSub         => 0x02,
                          :kDupCheckDesc        => 0x04,
                          :kDupCheckSubDesc     => 0x06,
                          :kDupCheckSubThenDesc => 0x08 }
    

    COLUMN_TO_ENUM_MAP = { :type      => RECTYPE_MAP,
                           :dupmethod => RECDUPIN_MASK,
                           :dupmethod => RECDUPMETHOD_MASK }

    # Columns which need ENUMS: dupmethod, dupin, type? search?
    # Foreign keys: transcoder, storagegroup
    def initialize(data_source, db_instance)
      @db = db_instance
      
      if data_source.class == Array
        # If we're given an array, it's from the database, so construct via DATABASE_COLUMNS
        DATABASE_COLUMNS.each_with_index do |col, i|
          send("#{col}=", data_source[i])
        end
      elsif data_source.class == Program
        # If we're initialising from a Program, invoke our new_from_program() method
        new_from_program(data_source)
      end
      
    end
    
    def new_from_program(program)
      defaults = { :recordid => nil,
                   :type => 1, # Single recording
                   :profile => "Default",
                   :recpriority => 0,
                   :autoexpire =>  @db.get_setting('AutoExpireDefault'),
                   :maxepisodes => 0,
                   :maxnewest => 0,
                   :startoffset => @db.get_setting('DefaultStartOffset'),
                   :endoffset => @db.get_setting('DefaultEndOffset'),
                   :recgroup => "Default",
                   :dupmethod => 6, # 
                   :dupin => 15,
                   :search => 0,
                   :autotranscode => @db.get_setting('AutoTranscode'),
                   :autocommflag => @db.get_setting('AutoTranscode'),
                   :autouserjob1 => @db.get_setting('AutoRunUserJob1'),
                   :autouserjob2 => @db.get_setting('AutoRunUserJob2'),
                   :autouserjob3 => @db.get_setting('AutoRunUserJob3'),
                   :autouserjob4 => @db.get_setting('AutoRunUserJob4'),
                   :findday => 0,
                   :findtime => 0,
                   :findid => 0,
                   :inactive => 0,
                   :parentid => 0,
                   :transcoder => @db.get_setting('DefaultTranscoder'),
                   :tsdefault => 1,
                   :playgroup => 'Default',
                   :prefinput => 0,
                   :next_record => 0,
                   :last_record => 0,
                   :last_delete => 0,
                   :storagegroup => 'Default',
                   :avg_delay => 0 }
      
      self.chanid = program.chanid
      self.starttime = program.starttime
      self.startdate = program.starttime
      self.endtime = program.endtime
      self.enddate = program.endtime
      self.title = program.title
      self.subtitle = program.subtitle
      self.description = program.description
      self.category = program.category
      self.seriesid = program.seriesid
      self.programid = program.programid

      defaults.each_pair do |k,v|
        self.send("#{k}=", v)
      end
      
      # Station assignment from the channel object. Needs caching
      channels = @db.list_channels(:chanid => self.chanid)
      self.station = channels[0].name if channels.length == 1
    end
    
    def save
      query =  "REPLACE INTO record (" + DATABASE_COLUMNS.collect { |c| c.to_s }.join(",") + ")"
      query += " VALUES (" + (1..DATABASE_COLUMNS.length).map {'?'}.join(',') + ")"

      puts query
      
      st = @db.connection.prepare(query)
      st_args = DATABASE_COLUMNS.collect { |c| send(c) }
      result = st.execute(*st_args)
      
      if result.affected_rows() == 1
        # Set the recordid from the replace
        @recordid = result.insert_id()
        return true
      else
        return false
      end
    end
    
    def destroy
      # We should have a valid recordid before we continue
      return false if recordid < 1
      
      query = "DELETE FROM record WHERE recordid = ?"
      
      st = @db.connection.prepare(query)
      result = st.execute(@recordid)
      
      result.affected_rows() == 1
    end
    
    def to_s; DATABASE_COLUMNS.collect { |v| "#{v}: '#{send(v) || 'nil'}'" }.join(", "); end
    
  end
  
end

