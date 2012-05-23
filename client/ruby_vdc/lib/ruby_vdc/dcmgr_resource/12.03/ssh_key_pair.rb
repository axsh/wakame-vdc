# -*- coding: utf-8 -*-
module DcmgrResource::V1203
  class SshKeyPair < Base
    
    def self.list(params = {})
      self.find(:all,:params => params)
    end
    
    def self.show(uuid)
      self.get(uuid)
    end
    
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
end
