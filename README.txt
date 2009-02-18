= ruby-mythtv
  
== Description

A pure Ruby implementation of the MythTV Backend protocol, and a MySQL database wrapper to allow interaction with a MythTV server. Features include browsing and streaming of recordings, thumbnail generation, listing channels and programs, and recording schedule editing. Currently the most complicated use of the gem is from the tests in the test/ subdirectory. See http://github.com/nickludlam/ruby-mythtv for more details. 

== Requirements

This gem relies on the 'mysql' gem, and obviously requires a MythTV server to talk to. The Gem is version independent, and currently knows how to speak the backend protocol versions 31 and 40. It can also cope with different versions of the MySQL database schema.

== Install

To install from RubyForge:

  $ gem install ruby-mythtv

To install from GitHub:

  $ gem sources -a http://gems.github.com/ (only required once)
  $ gem install nickludlam-ruby-mythtv

== Source

The ruby-mythtv source is available on GitHub at

  http://github.com/nickludlam/ruby-mythtv
  
and can be cloned from

  git://github.com/nickludlam/ruby-mythtv.git
  
== Basic usage

If you want to enumerate the current recordings, select one and stream it to disk, then it would
look something like this.

  require 'ruby-mythtv'
  
  # Connect to the server
  mythbackend = MythTV.connect_backend(:host => 'mythtv.localdomain')
  
  # Get an array of recordings
  recordings = mythbackend.query_recordings
  
  # Download a recording
  mythbackend.download(recordings[0])
  
  # Stream a recording into a block
  mythbackend.stream(recordings[0], :transfer_blocksize => 65535) do |chunk|
    ..do something with the 64k chunk..
  end
  
  # Generate a thumbnail of the most recent recording, at 60 seconds in from the start
  preview_thumbnail = mythbackend.preview_image(recordings[0], :secs_in => 60)
  File.open('preview_thumbnail.png', 'w') { |f| f.write(preview_thumbnail) }

== Advanced usage

If you wanted to search for a particular program name, and set up a schedule

  require 'ruby-mythtv'

  # Connect to the server
  mythbackend, mythdb = MythTV.connect(:host => 'mythtv.localdomain',
                                       :database_password => 'password')

  # Find matches on our search term, and limit the results to 5 matches
  programs = mythdb.list_programs(:conditions => ['title LIKE ?', "%SEARCH TERM%"],
                                  :limit => 5)
  
  # Take the first program match, and convert it to a recording schedule
  new_schedule = MythTV::RecordingSchedule.new(programs[0], mythdb)
  new_schedule.save
  
  # Signal the backend of recording changes for our recording schedule entry
  mythbackend.reschedule_recordings(new_schedule.recordid)
  
  # Let the backend resolve matches
  sleep(5)

  # Enumerate the list of pending recordings, find ours, and check for any conflicts
  pending_recordings = mythbackend.query_pending
  conflicts = pending_recordings.find { |p| p.recordid == new_schedule.recordid &&
                                            p.recstatus_sym == :rsConflict }
  
  # If conflicts is empty, then all is good. If it is populated, then action needs
  # to be taken, such as bumping the priority, or removing the clashes....

== Author

Written in 2008-2009 by Nick Ludlam <nick@recoil.org>

== License

Copyright (c) 2008,2009 Nick Ludlam

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

