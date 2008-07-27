= Ruby-mythtv
  
== Description

A pure Ruby implementation of the MythTV Backend protocol to allow interaction with a MythTV server. Features include browsing and streaming of recordings, and thumbnail generation. See http://github.com/nickludlam/ruby-mythtv for more details.

== Requirements

This gem does not yet support multiple protocol versions, so it requires an up-to-date installation of MythTV v0.21, and specifically implements protocol version 40. For more information on the history of the MythTV protocol, see http://www.mythtv.org/wiki/index.php/Protocol

== Install

  $ gem sources -a http://gems.github.com/ (only required once)
  $ gem install nickludlam-ruby-mythtv
  
== Source

The ruby-mythtv source is available on GitHub at

  http://github.com/nickludlam/ruby-mythtv
  
and can be cloned from

  git://github.com/nickludlam/ruby-mythtv.git
  
== Basic usage

  require 'ruby-mythtv'
  
  # Connect to the server
  backend = MythTV::Backend.new(:host => 'mythtv.localdomain')
  
  # Get an array of recordings
  recordings = backend.query_recordings
  
  # Download a recording
  @backend.download(recordings[0])
  
  # Stream a recording into a block
  @backend.stream(recordings[0], :transfer_blocksize => 65535) do |chunk|
    ..do something with the 64k chunk..
  end
  
  # Generate a thumbnail of the most recent recording, at 60 seconds in from the start
  preview_thumbnail = @backend.preview_image(recordings[0], :secs_in => 60)
  File.open('preview_thumbnail.png', 'w') { |f| f.write(preview_thumbnail) }

== Author

Written in 2008 by Nick Ludlam <nick@recoil.org>

== License

Copyright (c) 2008 Nick Ludlam

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

