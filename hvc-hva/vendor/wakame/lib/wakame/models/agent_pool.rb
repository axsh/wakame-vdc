
module Wakame
  module Models
    class AgentPool < Sequel::Model
      plugin :schema
      plugin :hook_class_methods
      
      set_schema {
        primary_key :id, :type => Integer
        column :agent_pool_id, :int
        column :agent_id, :varchar, :unique=>true
        column :group_type, :int
        column :created_at, :datetime
        column :updated_at, :datetime
      }

      before_create(:set_created_at) do
        self.updated_at = self.created_at = Time.now
      end
      before_update(:set_updated_at) do
        self.updated_at = Time.now
      end

      GROUP_ACTIVE=1
      GROUP_OBSERVED=2

      DEFAULT_POOL_ID=1

      def self.instance
        self
      end

      def self.reset
        filter(:agent_pool_id=>DEFAULT_POOL_ID).all.each { |row|
          agent = Service::Agent.find(row[:agent_id])
          if agent
            agent.cloud_host_id = nil
            agent.save
          else
            row.delete
          end
        }
      end

      def self.group_active
        filter(:agent_pool_id=>DEFAULT_POOL_ID, :group_type=>GROUP_ACTIVE).all.map {|row| row[:agent_id] }
      end

      def self.group_observed
        filter(:agent_pool_id=>DEFAULT_POOL_ID, :group_type=>GROUP_OBSERVED).all.map {|row| row[:agent_id] }
      end

      def self.agent_find_or_create(agent_id)
        agent = Service::Agent.find(agent_id)
        if agent.nil?
          agent = Service::Agent.new
          agent.id = agent_id
          Wakame.log.debug("#{self.class}: Created new agent object with Agent ID: #{agent_id}")
        end
        agent
      end

      def self.register_as_observed(agent)
        raise ArgumentError unless agent.is_a? Service::Agent
        row = find_or_create(:agent_id=>agent.id, :agent_pool_id=>DEFAULT_POOL_ID)
        if row[:group_type].nil? || row[:group_type] == GROUP_ACTIVE
          # The agent is being registered at first time.
          # Move the reference from active group to observed group.
          row[:group_type]=GROUP_OBSERVED
          row.save
          Wakame.log.debug("#{self.class}: Register agent to observed group: #{agent.id}")
        elsif 
          row[:group_type]=GROUP_OBSERVED
        end
      end

      def self.register(agent)
        raise ArgumentError unless agent.is_a?(Service::Agent)
        row = find_or_create(:agent_id=>agent.id, :agent_pool_id=>DEFAULT_POOL_ID)
        if row[:group_type].nil? || row[:group_type] == GROUP_OBSERVED
          # The agent is being registered at first time.
          # Move the reference from observed group to the active group.
          row[:group_type]=GROUP_ACTIVE
          row.save
          
          Wakame.log.debug("#{self}: Register agent to active group: #{agent.id}")
          ED.fire_event(Event::AgentMonitored.new(agent))
        elsif row[:group_type] == GROUP_ACTIVE
        end
      end

      def self.unregister(agent)
        raise ArgumentError unless agent.is_a?(Service::Agent)
        row = first(:agent_id=>agent.id, :agent_pool_id=>DEFAULT_POOL_ID)
        if row.nil?
        else
          row.delete
          Wakame.log.debug("#{self}: Unregister agent: #{agent.id}")
          ED.fire_event(Event::AgentUnMonitored.new(agent))
        end
      end

      def self.find_agent(agent_id)
        raise "The agent ID \"#{agent_id}\" is not registered in the pool" unless first(:agent_id=>agent_id, :agent_pool_id=>DEFAULT_POOL_ID)
        Service::Agent.find(agent_id) || raise("The agent ID #{agent_id} is registered. but not in the database.")
      end

    end
  end
  
  Initializer.loaded_classes << Models::AgentPool if const_defined? :Initializer

end
