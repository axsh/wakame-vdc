module Frontend
  autoload :Schema, '../common/lib/schema'
  
  module Models
     autoload :BaseNew, '../common/lib/models/base_new'
     autoload :Account, '../common/lib/models/account'
     autoload :Tag, '../common/lib/models/tag'
     autoload :TagMapping, '../common/lib/models/tag_mapping'
     autoload :User, '../common/lib/models/user'
     autoload :Authz, '../common/lib/models/authz'

     module DcmgrResource
       autoload :Base, '../common/lib/models/dcmgr_resource/base'
       autoload :Account, '../common/lib/models/dcmgr_resource/account'
       autoload :Volume, '../common/lib/models/dcmgr_resource/volume'
       autoload :VolumeSnapshot, '../common/lib/models/dcmgr_resource/volume_snapshot'
       autoload :NetfilterGroup, '../common/lib/models/dcmgr_resource/netfilter_group'
       autoload :Instance, '../common/lib/models/dcmgr_resource/instance'
       autoload :Image, '../common/lib/models/dcmgr_resource/image'
       
       if Rails.env.development?
         autoload :Mock, '../common/lib/models/dcmgr_resource/mock'
       end
     end
   end
end

@dcmgr_config = YAML::load(ERB.new(IO.read(File.join(Rails.root,'../','common', 'config', 'database.yml'))).result)[Rails.env]
Frontend::Schema.connect "#{@dcmgr_config['adapter']}://#{@dcmgr_config['host']}/#{@dcmgr_config['database']}?user=#{@dcmgr_config['user']}&password=#{@dcmgr_config['password']}"