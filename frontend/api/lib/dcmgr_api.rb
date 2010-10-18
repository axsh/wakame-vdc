require 'configuration'

module Frontend
  module DcmgrApi
    extend self

    module Endpoints
      autoload :App, 'lib/dcmgr_api/endpoints/app'
    end
    
    class << self
       def configure(config_path=nil, &blk)
        return self if @conf

        if config_path.is_a?(String)
          raise "Could not find configration file: #{config_path}" unless File.exists?(config_path)
          code= <<-__END
          Configuration('global') do
            #{File.read(config_path)}
          end
          __END
          @conf = eval(code)
        else
          @conf = Configuration.for('global', &blk)
        end

        self
      end

      def start(config=nil)
        config ||= 'api.conf'
        configure(config)
        Endpoints::App
      end
    end
   end
   
   autoload :Schema,'../common/lib/schema'

   module Models
      autoload :BaseNew, '../common/lib/models/base_new'
      autoload :Account, '../common/lib/models/account'
      autoload :Tag, '../common/lib/models/tag'
      autoload :TagMapping, '../common/lib/models/tag_mapping'
      autoload :User, '../common/lib/models/user'
      autoload :Authz, '../common/lib/models/authz'
    end

    module Helpers
      autoload :AuthzHelper, '../common/lib/helpers/authz_helper'
    end 
end