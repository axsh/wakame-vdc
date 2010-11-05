module Frontend::Models
  module DcmgrResource
    class NetfilterGroup < Base

      def self.create(params)
        netfilter_group = self.new
        netfilter_group.name = params[:name]
        netfilter_group.description = params[:description]
        netfilter_group.rule = params[:rule]
        netfilter_group.save
        netfilter_group
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
end