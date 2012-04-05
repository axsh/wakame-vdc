# -*- coding: utf-8 -*-
module DcmgrResource

  @debug = false

  class << self
    attr_accessor :debug
  end
  
  class Base < ActiveResource::Base

    # self.site = 'http://your.dcmgr.api.server'
    self.timeout = 30
    self.format = :json
    self.prefix = '/api/'
    
    class << self
      
      def total_resource
        result = self.find(:first,:params => {:start => 0,:limit => 1})
        result.owner_total
      end

      def get_resource_state_count(resources, state)
        resource_count = 0
        unless resources.empty?   
          resources.each do |item|
            if item.state == state
              resource_count += 1;
            end
          end 
        end
        resource_count
      end
 
    end
    
  end
end

ActiveResource::Connection.class_eval do 
  
  private
  def default_header
    @default_header = {
      'X-VDC-ACCOUNT-UUID' => self.class.send(:class_variable_get,:@@vdc_account_uuid)
    }
  end
  
  def configure_http(http)
    http = apply_ssl_options(http)
    
    #add debug 
    http.set_debug_output($stderr) if DcmgrResource.debug
    
    # Net::HTTP timeouts default to 60 seconds.
        if @timeout
          http.open_timeout = @timeout
          http.read_timeout = @timeout
        end
    
    http
  end
end
