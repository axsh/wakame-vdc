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

DcmgrResource::Account = DcmgrResource::V1112::Account
DcmgrResource::HostNode = DcmgrResource::V1112::HostNode
DcmgrResource::Image = DcmgrResource::V1112::Image
DcmgrResource::Instance = DcmgrResource::V1112::Instance
DcmgrResource::InstanceSpec = DcmgrResource::V1112::InstanceSpec
DcmgrResource::SecurityGroup = DcmgrResource::V1112::SecurityGroup
DcmgrResource::SshKeyPair = DcmgrResource::V1112::SshKeyPair
DcmgrResource::StorageNode = DcmgrResource::V1112::StorageNode
DcmgrResource::Volume = DcmgrResource::V1112::Volume
DcmgrResource::VolumeSnapshot = DcmgrResource::V1112::VolumeSnapshot
