module MythTV
  
  class Program < ActiveRecord::Base
    set_table_name 'program'
    set_primary_keys 'chanid', 'starttime', 'manualid'

    belongs_to :channel, :foreign_key => 'chanid'
    
    def inspect
      "#{title} : #{subtitle} [#{category}] on at #{starttime} on channel id #{chanid}"
    end
  end
  
end
