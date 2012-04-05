# -*- coding: utf-8 -*-
module DcmgrResource
  class SecurityGroup < Base

    def self.create(params)
      security_group = self.new
      security_group.description = params[:description]
      security_group.rule = params[:rule]
      security_group.save
      security_group
    end

    # workaround for the bug:
    #  the value of the key "rule" is encoded to JSON wrongly by
    #  ActiveSupport::JSON encoder.
    #  "{\"security_group\":{\"description\":\"\",\"rule\":[[null,[],null]]}}"
    #  So it has to use the encoder from JSON library.
    def to_json(options={})
      require 'json'
      {'security_group'=>@attributes}.to_json
    end

    def self.list(params = {})
     self.find(:all,:params => params)
    end

    def self.show(uuid)
      self.get(uuid)
    end
              
    def self.update(uuid,params)
      self.put(uuid,params).body
    end
    
    def self.destroy(uuid)
      self.delete(uuid).body
    end      
  end
end
