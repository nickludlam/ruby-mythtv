module MythTV
  
  class Setting < ActiveRecord::Base
    set_table_name 'settings'
    set_primary_key nil
    
    def self.data_for_value(value, hostname=nil)
      setting = self.find(:first, :conditions => { :value => value, :hostname => hostname})
      setting ? setting.data : nil
    end
  end
  
end