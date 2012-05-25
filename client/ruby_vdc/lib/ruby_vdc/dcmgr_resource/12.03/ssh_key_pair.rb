# -*- coding: utf-8 -*-
module DcmgrResource::V1203
  module SshKeyPairMethods
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def create(params)
        ssh_key_pair = self.new
        ssh_key_pair.download_once = params[:download_once]
        ssh_key_pair.save
        ssh_key_pair
      end
      
      def destroy(uuid)
        self.delete(uuid).body
      end
    end
  end

  class SshKeyPair < Base
    include DcmgrResource::ListMethods
    include SshKeyPairMethods
  end
end
