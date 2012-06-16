# -*- coding: utf-8 -*-

require 'active_resource'

module Hijiki
  # configuration file loader. Need to call this 
  def self.load(spec_yml)
    DcmgrResource::V1203::InstanceSpec.load_spec(spec_yml)
  end
  
  module DcmgrResource

    require 'hijiki/dcmgr_resource/base'

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
      autoload :LoadBalancer,   'hijiki/dcmgr_resource/12.03/load_balancer'

      autoload :SecurityGroupMethods,  'hijiki/dcmgr_resource/12.03/security_group'
      autoload :SshKeyPairMethods,     'hijiki/dcmgr_resource/12.03/ssh_key_pair'
      autoload :VolumeMethods,         'hijiki/dcmgr_resource/12.03/volume'
      autoload :VolumeSnapshotMethods, 'hijiki/dcmgr_resource/12.03/volume_snapshot'
      autoload :BackupObjectMethods, 'hijiki/dcmgr_resource/12.03/backup_object'
      autoload :LoadBalancerMethods, 'hijiki/dcmgr_resource/12.03/load_balancer'
    end

  end
end
