module DcmgrResource
  class Base < ActiveResource::Base
    #todo:config
    self.site = "http://api.dcmgr.ubuntu.local/"
    self.timeout = 30
    self.format = :json
    self.prefix = '/api/'
    
    @@debug = false
    
    class << self
      
      def total_resource
        result = self.find(:first,:params => {:start => 0,:limit => 1})
        result.owner_total
      end
      # If headers are not defined in a given subclass, then obtain
      # headers from the superclass.
      
      def set_debug(debug = true)
        @@debug = debug
      end
    end
    
    ActiveResource::Connection.class_eval do 

      private
      def configure_http(http)
        http = apply_ssl_options(http)

        #add debug 
        http.set_debug_output($stderr) if @@debug

        # Net::HTTP timeouts default to 60 seconds.
        if @timeout
          http.open_timeout = @timeout
          http.read_timeout = @timeout
        end

        http
      end
    end
  end
end
