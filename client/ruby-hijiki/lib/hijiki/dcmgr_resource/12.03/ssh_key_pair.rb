# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  module SshKeyPairMethods
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def create(params)
        ssh_key_pair = self.new
        ssh_key_pair.display_name = params[:display_name]
        ssh_key_pair.description = params[:description]
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
    include Hijiki::DcmgrResource::ListMethods
    include SshKeyPairMethods
  end
end
