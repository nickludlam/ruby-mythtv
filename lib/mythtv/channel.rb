module MythTV
  
  class Channel < ActiveRecord::Base
    set_table_name 'channel'
    set_primary_key :chanid

    #has_many :recording_schedules, :foreign_key => 'chanid'
    has_many :programs, :foreign_key => 'chanid', :class_name => "MythTV::Program"
  end
  
end