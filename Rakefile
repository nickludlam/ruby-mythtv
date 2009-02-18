require 'rubygems'
require 'rake/gempackagetask'
require 'rake/testtask'

spec = Gem::Specification.new do |s|
  s.name = 'ruby-mythtv'
  s.version = '0.3.0'
 
  s.specification_version = 2 if s.respond_to? :specification_version=
 
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.date = %q{2009-02-18}
  s.description = %q{Ruby implementation of the MythTV communication protocol, and interface to the MythTV database}
  s.authors = [ 'Nick Ludlam' ]
  s.email = %q{nick@recoil.org}
  s.extra_rdoc_files = [ 'History.txt', 'License.txt', 'README.txt', 'Todo.txt' ]
  s.files = [ 'History.txt', 'License.txt', 'README.txt', 'Rakefile', 'Todo.txt' ] + Dir["lib/*.rb"] + Dir["lib/mythtv/*.rb"] + Dir["test/*.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/nickludlam/ruby-mythtv/}
  s.rdoc_options = ['--main', 'README.txt']
  s.require_paths = ['lib']
  s.rubyforge_project = %q{ruby-mythtv}
  s.rubygems_version = %q{0.3.0}
  
  s.add_dependency('mysql')
  s.add_dependency('activerecord')
  s.add_dependency('composite_primary_keys')
  
  s.summary = %q{Ruby implementation of the MythTV backend protocol}
  s.test_files = Dir["test/*.rb"]
end

Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_zip = true
  pkg.need_tar = true 
end 

task :build => "pkg/#{spec.name}-#{spec.version}.gem" do
  puts "Generated latest version"
end

desc "Run basic unit tests"
Rake::TestTask.new("test") do |t|
  t.pattern = ENV["TESTFILES"] || ['test/test_backend.rb', 'test/test_db.rb']
  t.verbose = true
  t.warning = true
end

Rake::TestTask.new('test:db') do |t|
  t.pattern = ['test/test_db.rb']
  t.verbose = true
end

Rake::TestTask.new('test:backend') do |t|
  t.pattern = ['test/test_backend.rb']
  t.verbose = true
end

  
desc "Run unit tests as default"
task :default => :test
