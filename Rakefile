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
  $:.unshift 'lib'
  require "#{File.dirname(__FILE__)}/./.bundle/environment"
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

  desc 'Install a range of ip addrs and paired mac addr together'
  task :install_ip => [:environment] do
    require 'dcmgr'
    require 'ipaddr'
    ip_group = Dcmgr::Models::IpGroup.find(:name=>ENV['IP_GROUP']) || abort("No such ip group: #{ENV['IP_GROUP']}")
    ip_start = IPAddr.new(ENV['IP_BEGIN'])
    range_num = ENV['RANGE'].to_i

    Dcmgr::Models::Ip.db.transaction do
      range_num.times { |n|
        ip_cur = IPAddr.new(ip_start.to_i + n, Socket::AF_INET)
        #random mac addr generation
        mac = Array.new(6).map{"%02x" % rand(0xff) }.join(':')
        Dcmgr::Models::Ip.create({:ip=>ip_cur.to_s, :mac=>mac, :ip_group_id=>ip_group.id,:status=>0})
      }
    end
  end

  task :reset => [ :drop, :init ]
end
