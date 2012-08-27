# -*- coding: utf-8 -*-

module Hijiki
  # configuration file loader. Need to call this 
  def self.load(spec_yml)
    DcmgrResource::V1203::InstanceSpec.load_spec(spec_yml)
  end
  
  require 'hijiki/request_attribute'
    
  module DcmgrResource

    # Helps to create alias module names for the specified version of
    # active resource classes.
    # setup_aliases(:V1203) does the similar things with following:
    # 
    # module Hijiki::DcmgrResource
    #   Account  = V1203::Account
    #   Image    = V1203::Image
    #   Instance = V1203::Instance
    #   Volume   = V1203::Volume
    #   ...
    #   ...
    # end
    def self.setup_aliases(version_sym, namespace=self)
      raise ArgumentError, "Undefined API version: #{version_sym}" unless self.const_get(version_sym)
      raise ArgumentError, "Invalid namespace class."  unless namespace.is_a?(Module)

      version_mod = Hijiki::DcmgrResource.const_get(version_sym)
      namespace.module_eval {
        version_mod.constants(false).each { |k|
          next if k.to_sym == :Base
          self.const_set(k, version_mod.const_get(k))
        }
      }
    end

    module Common
      require 'hijiki/dcmgr_resource/base'
    end

    module V1203
      require 'hijiki/dcmgr_resource/12.03/base'

      autoload :Account,        'hijiki/dcmgr_resource/12.03/account'
      autoload :DcNetwork,      'hijiki/dcmgr_resource/12.03/dc_network'
      autoload :HostNode,       'hijiki/dcmgr_resource/12.03/host_node'
      autoload :Image,          'hijiki/dcmgr_resource/12.03/image'
      autoload :Instance,       'hijiki/dcmgr_resource/12.03/instance'
      autoload :InstanceSpec,   'hijiki/dcmgr_resource/12.03/instance_spec'
      autoload :Network,        'hijiki/dcmgr_resource/12.03/network'
      autoload :NetworkVif,     'hijiki/dcmgr_resource/12.03/network_vif'
      autoload :NetworkService, 'hijiki/dcmgr_resource/12.03/network_service'
      autoload :SecurityGroup,  'hijiki/dcmgr_resource/12.03/security_group'
      autoload :SshKeyPair,     'hijiki/dcmgr_resource/12.03/ssh_key_pair'
      autoload :StorageNode,    'hijiki/dcmgr_resource/12.03/storage_node'
      autoload :Volume,         'hijiki/dcmgr_resource/12.03/volume'
      autoload :BackupObject,   'hijiki/dcmgr_resource/12.03/backup_object'
      autoload :LoadBalancer,   'hijiki/dcmgr_resource/12.03/load_balancer'
    end

  end
end
