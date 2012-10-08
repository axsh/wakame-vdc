require 'rubygems'

setup_rb = File.expand_path('../../vendor/bundle/bundler/setup.rb', __FILE__)
if File.exists?(setup_rb)
  load setup_rb
else
  # Set up gems listed in the Gemfile.
  gemfile = File.expand_path('../../Gemfile', __FILE__)
  begin
    ENV['BUNDLE_GEMFILE'] = gemfile
    require 'bundler'
    Bundler.setup
  rescue Bundler::GemNotFound => e
    STDERR.puts e.message
    STDERR.puts "Try running `bundle install`."
    exit!
  end if File.exist?(gemfile)
end
