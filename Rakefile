require 'rake/clean'

task :default => :spec

desc 'Run tests'
task :test do
  sh "testrb test/*_test.rb"
end

desc 'Run specs'
task :spec do
  sh "spec -c test/*_spec.rb"
end

