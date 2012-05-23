# -*- coding: utf-8 -*-

require 'active_resource'

module DcmgrResource

  require 'ruby_vdc/dcmgr_resource/base'

  module V1112
    require 'ruby_vdc/dcmgr_resource/11.12/base'

    autoload :Account,        'ruby_vdc/dcmgr_resource/11.12/account'
    autoload :HostNode,       'ruby_vdc/dcmgr_resource/11.12/host_node'
    autoload :Image,          'ruby_vdc/dcmgr_resource/11.12/image'
    autoload :Instance,       'ruby_vdc/dcmgr_resource/11.12/instance'
    autoload :InstanceSpec,   'ruby_vdc/dcmgr_resource/11.12/instance_spec'
    autoload :SecurityGroup,  'ruby_vdc/dcmgr_resource/11.12/security_group'
    autoload :SshKeyPair,     'ruby_vdc/dcmgr_resource/11.12/ssh_key_pair'
    autoload :StorageNode,    'ruby_vdc/dcmgr_resource/11.12/storage_node'
    autoload :Volume,         'ruby_vdc/dcmgr_resource/11.12/volume'
    autoload :VolumeSnapshot, 'ruby_vdc/dcmgr_resource/11.12/volume_snapshot'
  end

  module V1203
    require 'ruby_vdc/dcmgr_resource/12.03/base'

    autoload :Account,        'ruby_vdc/dcmgr_resource/12.03/account'
    autoload :HostNode,       'ruby_vdc/dcmgr_resource/12.03/host_node'
    autoload :Image,          'ruby_vdc/dcmgr_resource/12.03/image'
    autoload :Instance,       'ruby_vdc/dcmgr_resource/12.03/instance'
    autoload :InstanceSpec,   'ruby_vdc/dcmgr_resource/12.03/instance_spec' # Obsolete
    autoload :SecurityGroup,  'ruby_vdc/dcmgr_resource/12.03/security_group'
    autoload :SshKeyPair,     'ruby_vdc/dcmgr_resource/12.03/ssh_key_pair'
    autoload :StorageNode,    'ruby_vdc/dcmgr_resource/12.03/storage_node'
    autoload :Volume,         'ruby_vdc/dcmgr_resource/12.03/volume'
    autoload :VolumeSnapshot, 'ruby_vdc/dcmgr_resource/12.03/volume_snapshot'
  end

end

