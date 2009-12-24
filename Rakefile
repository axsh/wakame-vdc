require 'rake/clean'

task :default => :spec

desc 'Run specs'
task :spec do
  sh "./bin/spec -fs -c spec/*_spec.rb"
end

task :environment do
  $:.unshift 'lib'
  require "#{File.dirname(__FILE__)}/vendor/gems/environment"
  require 'dcmgr'
  Dcmgr.configure 'dcmgr.conf'
end

task :shell do
  sh "ruby lib/dcmgr/shell.rb dcmgr.conf"
end

task :run do
  sh "./bin/shotgun -p 3000 config.ru"
end

namespace :db do
  desc 'Create all database tables'
  task :init => [ :environment ] do
    Dcmgr::Schema.create!
  end

  desc 'Drop all database tables'
  task :drop => [ :environment ] do
    Dcmgr::Schema.drop!
  end

  desc 'Create initial data'
  task :initial_data => [ :environment ] do
    Dcmgr::Schema.initial_data
  end

  task :reset => [ :drop, :init ]
end
