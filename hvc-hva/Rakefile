# -*- ruby -*-
require(File.join(File.dirname(__FILE__), 'config', 'boot'))
Wakame::Bootstrap.boot!

require 'rubygems'
begin
  require 'rake'
rescue LoadError
  puts 'This script should only be accessed via the "rake" command.'
  puts 'Installation: gem install rake -y'
  exit
end
require 'rake/clean'

#Dir['tasks/**/*.rake'].each { |t| load t }

# task :default => [:spec, :features]
# vim: syntax=Ruby
