# -*- coding: utf-8

require 'hijiki'

module Hijiki::DcmgrResource

  if false
    Account = V1112::Account
    HostNode = V1112::HostNode
    Image = V1112::Image
    Instance = V1112::Instance
    InstanceSpec = V1112::InstanceSpec
    Network = V1112::Network
    SecurityGroup = V1112::SecurityGroup
    SshKeyPair = V1112::SshKeyPair
    StorageNode = V1112::StorageNode
    Volume = V1112::Volume
    VolumeSnapshot = V1112::VolumeSnapshot
  else
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
  end

end
