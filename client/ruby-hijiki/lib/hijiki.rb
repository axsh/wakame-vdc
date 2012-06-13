# -*- coding: utf-8 -*-

require 'active_resource'

module Hijiki
  module DcmgrResource

    require 'hijiki/dcmgr_resource/base'

    module V1112
      require 'hijiki/dcmgr_resource/11.12/base'

      autoload :Account,        'hijiki/dcmgr_resource/11.12/account'
      autoload :HostNode,       'hijiki/dcmgr_resource/11.12/host_node'
      autoload :Image,          'hijiki/dcmgr_resource/11.12/image'
      autoload :Instance,       'hijiki/dcmgr_resource/11.12/instance'
      autoload :InstanceSpec,   'hijiki/dcmgr_resource/11.12/instance_spec'
      autoload :Network,        'hijiki/dcmgr_resource/11.12/network'
      autoload :SecurityGroup,  'hijiki/dcmgr_resource/11.12/security_group'
      autoload :SshKeyPair,     'hijiki/dcmgr_resource/11.12/ssh_key_pair'
      autoload :StorageNode,    'hijiki/dcmgr_resource/11.12/storage_node'
      autoload :Volume,         'hijiki/dcmgr_resource/11.12/volume'
      autoload :VolumeSnapshot, 'hijiki/dcmgr_resource/11.12/volume_snapshot'
    end

    module V1203
      require 'hijiki/dcmgr_resource/12.03/base'

      autoload :Account,        'hijiki/dcmgr_resource/12.03/account'
      autoload :HostNode,       'hijiki/dcmgr_resource/12.03/host_node'
      autoload :Image,          'hijiki/dcmgr_resource/12.03/image'
      autoload :Instance,       'hijiki/dcmgr_resource/12.03/instance'
      autoload :InstanceSpec,   'hijiki/dcmgr_resource/12.03/instance_spec'
      autoload :Network,        'hijiki/dcmgr_resource/12.03/network'
      autoload :SecurityGroup,  'hijiki/dcmgr_resource/12.03/security_group'
      autoload :SshKeyPair,     'hijiki/dcmgr_resource/12.03/ssh_key_pair'
      autoload :StorageNode,    'hijiki/dcmgr_resource/12.03/storage_node'
      autoload :Volume,         'hijiki/dcmgr_resource/12.03/volume'
      autoload :VolumeSnapshot, 'hijiki/dcmgr_resource/12.03/volume_snapshot'
      autoload :BackupObject,   'hijiki/dcmgr_resource/12.03/backup_object'

      autoload :InstanceMethods,       'hijiki/dcmgr_resource/12.03/instance'
      autoload :SecurityGroupMethods,  'hijiki/dcmgr_resource/12.03/security_group'
      autoload :SshKeyPairMethods,     'hijiki/dcmgr_resource/12.03/ssh_key_pair'
      autoload :VolumeMethods,         'hijiki/dcmgr_resource/12.03/volume'
      autoload :VolumeSnapshotMethods, 'hijiki/dcmgr_resource/12.03/volume_snapshot'
      autoload :BackupObjectMethods, 'hijiki/dcmgr_resource/12.03/backup_object'
    end

  end
end
