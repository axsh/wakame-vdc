module Dcmgr
  module Models
    class Instance < Base
      set_dataset :instances
      set_prefix_uuid 'I'
      
      many_to_one :account
      many_to_one :user

      many_to_one :image_storage
      many_to_one :hv_agent

      many_to_many :tags, :join_table=>:tag_mappings, :left_key=>:target_id,
      :conditions=>{:target_type=>TagMapping::TYPE_INSTANCE}

      module ExtendIpAssoc
        def find_by_group_name(group_name)
          filter(:ip_group_id=>IpGroup.find(:name=>group_name).id)
        end
      end
      one_to_many :ip, :extend=>ExtendIpAssoc

      STATUS_TYPE_OFFLINE = 0
      STATUS_TYPE_RUNNING = 1
      STATUS_TYPE_ONLINE = 2
      STATUS_TYPE_TERMINATING = 3

      STATUS_TYPES = {
        STATUS_TYPE_OFFLINE => :offline,
        STATUS_TYPE_RUNNING => :running,
        STATUS_TYPE_ONLINE => :online,
        STATUS_TYPE_TERMINATING => :terminating,
      }
      
      set_dataset filter({~:status => Instance::STATUS_TYPE_OFFLINE} |
                         ({:status => Instance::STATUS_TYPE_OFFLINE} & (:status_updated_at > Time.now - 3600)))
      
      def physical_host
        if self.hv_agent
          self.hv_agent.physical_host
        else
          nil
        end
      end

      def status_sym
        STATUS_TYPES[self.status]
      end

      def status_sym=(sym)
        match = STATUS_TYPES.find{|k,v| v == sym}
        return nil unless match
        self.status = match[0]
      end

      def ip_addresses
        self.ip.each{|ip| ip.ip}
      end

      def mac_addresses
        self.ip.each{|ip| ip.mac}
      end

      def before_create
        super
        self.status = STATUS_TYPE_OFFLINE unless self.status
        self.status_updated_at = Time.now
        Dcmgr::logger.debug "becore create: status = %s" % self.status
        unless self.hv_agent
          physical_host = PhysicalHost.assign(self)
          self.hv_agent = physical_host.hv_agents[0]
        end
      end

      def after_create
        super
        Dcmgr::IPManager.assign_ips(self)
      end

      def validate
        errors.add(:account, "can't empty") unless self.account
        errors.add(:user, "can't empty") unless self.user
        
        # errors.add(:hv_agent, "can't empty") unless self.hv_agent
        errors.add(:image_storage, "can't empty") unless self.image_storage

        errors.add(:need_cpus, "can't empty") unless self.need_cpus
        errors.add(:need_cpu_mhz, "can't empty") unless self.need_cpu_mhz
        errors.add(:need_memory, "can't empty") unless self.need_memory
      end

      def run
        Dcmgr::http(self.host, 80).open {|http|
          res = http.get('/run')
          return res.success?
        }
      end

      def shutdown
        Dcmgr::http(self.host, 80).open {|http|
          res = http.get('/shutdown')
          return res.success?
        }
      end
    end
  end
end
