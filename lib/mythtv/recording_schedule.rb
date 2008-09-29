module MythTV
  
  class RecordingSchedule

    # Map the 'type' column to a string
    RS_TYPE_MAP = { 0 => :kNotRecording,
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
    RS_DUPIN_MASK = { :kDupsInRecorded    => 0x01,
                      :kDupsInOldRecorded => 0x02,
                      :kDupsInAll         => 0x0F,
                      :kDupsNewEpi        => 0x10,
                      :kDupsExRepeats     => 0x20,
                      :kDupsExGeneric     => 0x40,
                      :kDupsFirstNew      => 0x80 }
    #
    RS_DUPMETHOD_MASK = { :kDupCheckNone        => 0x01,
                          :kDupCheckSub         => 0x02,
                          :kDupCheckDesc        => 0x04,
                          :kDupCheckSubDesc     => 0x06,
                          :kDupCheckSubThenDesc => 0x08 }
    
                      
    COLUMN_TO_ENUM_MAP = { :type      => RS_TYPE_MAP,
                           :dupmethod => RS_DUPIN_MASK,
                           :dupmethod => RS_DUPMETHOD_MASK }

    # Columns which need ENUMS: dupmethod, dupin, type? search?
    # Foreign keys: transcoder, storagegroup
    def initialize(data_source, db_instance)
      @db = db_instance
      
      # Find out the attributes this class has from the schema calculations earlier
      columns = db_instance.table_columns[self.class]
      
      self.class.class_eval { attr_accessor(*columns) }
      
      @columns = columns
      
      if data_source.class == Array
        # If we're given an array, it's from the database, so construct via DATABASE_COLUMNS
        @db.table_columns[RecordingSchedule].each_with_index do |col, i|
          send("#{col}=", data_source[i])
        end
      elsif data_source.class == Program
        # If we're initialising from a Program, invoke our new_from_program() method
        new_from_program(data_source)
      end
      
    end
    
    # This method 
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
      query =  "REPLACE INTO record (" + @columns.collect { |c| c.to_s }.join(",") + ")"
      query += " VALUES (" + (1..@columns.length).map {'?'}.join(',') + ")"

      puts query
      
      st = @db.connection.prepare(query)
      st_args = @columns.collect { |c| send(c) }
      result = st.execute(*st_args)
      
      if result.affected_rows() == 1
        # Set the recordid from the replace
        @recordid = result.insert_id().to_s
        return true
      else
        return false
      end
    end
    
    # Re-select all the data from the database via the primary key, recordid
    def reload
      st_query =  "SELECT " + @db.table_columns[self.class].collect { |c| c.to_s }.join(",") + " FROM record"
      st_query += " WHERE recordid = ?"

      st = @db.connection.prepare(st_query)
      results = st.execute(@recordid)

      @db.table_columns[self.class].each_with_index do |col, i|
        send("#{col}=", result[i])
      end
    end
    
    # Remove the row from the database
    def destroy
      # We should have a valid recordid before we continue
      return false if recordid.to_i < 1
      
      st_query = "DELETE FROM record WHERE recordid = ?"
      st = @db.connection.prepare(st_query)
      result = st.execute(@recordid)
      
      result.affected_rows() == 1
    end
    
    # Enable more pleasant debugging through a to_s method
    def to_s; @columns.collect { |v| "#{v}: '#{send(v) || 'nil'}'" }.join(", "); end
    
  end
  
end

