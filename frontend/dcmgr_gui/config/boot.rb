require 'rubygems'

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

require 'ruby_vdc'

DcmgrResource::Account = DcmgrResource::V1203::Account
DcmgrResource::HostNode = DcmgrResource::V1203::HostNode
DcmgrResource::Image = DcmgrResource::V1203::Image
DcmgrResource::Instance = DcmgrResource::V1203::Instance
DcmgrResource::InstanceSpec = DcmgrResource::V1203::InstanceSpec
DcmgrResource::SecurityGroup = DcmgrResource::V1203::SecurityGroup
DcmgrResource::SshKeyPair = DcmgrResource::V1203::SshKeyPair
DcmgrResource::StorageNode = DcmgrResource::V1203::StorageNode
DcmgrResource::Volume = DcmgrResource::V1203::Volume
DcmgrResource::VolumeSnapshot = DcmgrResource::V1203::VolumeSnapshot
