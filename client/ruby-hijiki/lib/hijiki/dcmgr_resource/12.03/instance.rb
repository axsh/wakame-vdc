# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class Instance < Base
    initialize_user_result nil, [:id,
                                 :host_node,
                                 :cpu_cores,
                                 :memory_size,
                                 :arch,
                                 :image_id,
                                 :created_at,
                                 :state,
                                 :status,
                                 :ssh_key_pair,
                                 :hostname,
                                 :ha_enabled,
                                 :hypervisor,
                                 :display_name,
                                ]

    module ClassMethods
      include Hijiki::DcmgrResource::Common::ListMethods::ClassMethods

      def list(params = {})
        state = 'alive_with_terminated'
        if params.has_key?(:state) && !params[:state].nil?
          state = params[:state]
        end
        super(params.merge({:state=>state}))
      end
      
      def create(params)
        instance = self.new
        instance.image_id = params[:image_id]
        instance.host_pool_id = params[:host_pool_id]
        instance.host_name = params[:host_name]
        instance.user_data = params[:user_data]
        instance.security_groups = params[:security_groups]
        instance.ssh_key_id = params[:ssh_key]
        instance.display_name = params[:display_name]

        instance.vifs = params[:vifs] if params[:vifs]

        is = InstanceSpec.show(params[:instance_spec_id]) || raise("Unknown instance spec: #{params[instance_spec_id]}")
        instance.cpu_cores = is.cpu_cores
        instance.memory_size = is.memory_size
        instance.hypervisor = is.hypervisor
        instance.quota_weight = is.quota_weight

        # rename the key to instance_spec_name.
        instance.instance_spec_name = params[:instance_spec_id]
        
        instance.save
        instance
      end
      
      def destroy(instance_id)
        self.delete(instance_id).body
      end
      
      def reboot(instance_id)
        result = self.find(instance_id).put(:reboot)
        result.body
      end

      def start(instance_id)
        result = self.find(instance_id).put(:start)
        result.body
      end

      def stop(instance_id)
        result = self.find(instance_id).put(:stop)
        result.body
      end

      def update(instance_id,params)
        self.put(instance_id,params).body
      end

      def backup(instance_id, params)
        result = self.find(instance_id).put(:backup,params.merge({:is_public =>false, :is_cacheable =>false}))
        result.body
      end

      def poweroff(instance_id)
        result = self.find(instance_id).put(:poweroff)
        result.body
      end

      def poweron(instance_id)
        result = self.find(instance_id).put(:poweron)
        result.body
      end
    end
    extend ClassMethods
  end
end
