# -*- coding: utf-8

require 'hijiki'

Hijiki.load(File.expand_path('config/instance_spec.yml', ::Rails.root))

module Hijiki::DcmgrResource

  Account = V1203::Account
  HostNode = V1203::HostNode
  Image = V1203::Image
  Instance = V1203::Instance
  InstanceSpec = V1203::InstanceSpec
  Network = V1203::Network
  SecurityGroup = V1203::SecurityGroup
  SshKeyPair = V1203::SshKeyPair
  StorageNode = V1203::StorageNode
  Volume = V1203::Volume
  VolumeSnapshot = V1203::VolumeSnapshot
  BackupObject = V1203::BackupObject
  LoadBalancer = V1203::LoadBalancer
end
