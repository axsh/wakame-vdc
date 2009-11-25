require 'rake/clean'

task :default => :spec

desc 'Run specs'
task :spec do
  sh "spec -fs -c spec/*_spec.rb"
end

task :environment do
  $:.unshift 'lib'
  require 'wakame-dcmgr'
  Wakame::Dcmgr.configure 'dcmgr.conf'
end

task :shell do
  sh "irb -r lib/wakame-dcmgr/shell"
end

namespace :db do
  desc 'Create all database tables'
  task :init => [ :environment ] do
    Wakame::Dcmgr::Schema.create!
  end

  desc 'Drop all database tables'
  task :drop => [ :environment ] do
    Wakame::Dcmgr::Schema.drop!
  end

  task :reset => [ :drop, :init ]
end
