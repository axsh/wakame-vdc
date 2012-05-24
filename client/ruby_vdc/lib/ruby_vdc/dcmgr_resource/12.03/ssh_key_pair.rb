# -*- coding: utf-8 -*-
module DcmgrResource::V1203
  module SshKeyPairMethods
    def self.create(params)
      ssh_key_pair = self.new
      ssh_key_pair.download_once = params[:download_once]
      ssh_key_pair.save
      ssh_key_pair
    end
    
    def self.destroy(uuid)
      self.delete(uuid).body
    end
  end

  class SshKeyPair < Base
    include DcmgrResource::ListMethods
    include SshKeyPairMethods
  end
end
