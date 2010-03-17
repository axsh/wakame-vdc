# -*- coding: utf-8 -*-
require 'rake/clean'

task :default => :spec

desc 'Run specs'
task :spec do
  sh "bundle exec spec -fs -c -r spec/specformat_silent spec"
end

namespace :spec do
  desc 'Run specs, detail mode'
  task :detail do
    sh "bundle exec spec -fs -b -c -r spec/specformat_detail spec"
  end
end

task :environment do
  begin
    require File.expand_path('../.bundle/environment', __FILE__)
  rescue LoadError
    require "rubygems"
    require "bundler"
    Bundler.setup
  end
  $:.unshift 'lib'
  require 'dcmgr'
  Dcmgr.configure 'dcmgr.conf'
end

task :shell do
  sh "bundle exec ruby lib/dcmgr/shell.rb dcmgr.conf"
end

namespace :shell do
  task :client do
    sh "bundle exec ruby lib/dcmgr/shell.rb -client"
  end
end

task :run do
  desc 'Run server for public'
  sh "bundle exec shotgun -p 3000 web/public/config.ru"
end

namespace :run do
  desc 'Run server for private'
  task :private do
    sh "bundle exec shotgun -p 3000 web/private/config.ru"
  end
end

def input(disp, empty=false)
  print disp
  while buf = STDIN.gets
    break if buf and (buf.length > 0 or empty)
  end
  
  buf.chomp
end

desc 'Create super user'
task :createsuperuser => [ :environment ] do
  user = input("Username: ")
  exit unless user
  system "stty -echo"
  begin
    passwd = input("Password: ")
    puts
    passwd_again = input("Password (again): ", true)
    puts
  end while passwd != passwd_again
  system "stty echo"
  
  Dcmgr::Schema.createsuperuser(user, passwd)
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

  desc 'Create sample data'
  task :sample_data => [ :environment ] do
    Dcmgr::Schema.load_data 'fixtures/sample_data'
  end

  task :reset => [ :drop, :init ]
end
