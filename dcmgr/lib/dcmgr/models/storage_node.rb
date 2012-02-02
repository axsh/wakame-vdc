# -*- coding: utf-8 -*-

require 'isono/models/node_state'

module Dcmgr::Models
  class StorageNode < AccountResource
    taggable 'sn'

    BACKINGSTORE_ZFS = 'zfs'
    BACKINGSTORE_RAW = 'raw'

    SUPPORTED_BACKINGSTORE = [BACKINGSTORE_ZFS, BACKINGSTORE_RAW]

    one_to_many :volumes
    one_to_many :volume_snapshots
    
    many_to_one :node, :class=>Isono::Models::NodeState, :key=>:node_id, :primary_key=>:node_id

    def_dataset_method(:online_nodes) do
      # SELECT * FROM `storage_nodes` WHERE ('node_id' IN (SELECT `node_id` FROM `node_states` WHERE (`state` = 'online')))
      r = Isono::Models::NodeState.filter(:state => 'online').select(:node_id)
      filter(:node_id => r)
    end
    
    def self.create_pool(params)
      self.create(:account_id => params[:account_id],
                  :node_id => params[:node_id],
                  :offering_disk_space => params[:offering_disk_space],
                  :transport_type => params[:transport_type],
                  :storage_type => params[:storage_type],
                  :export_path => params[:export_path],
                  :ipaddr => params[:ipaddr],
                  :snapshot_base_path => params[:snapshot_base_path])
    end

    def self.get_lists(uuid)
      self.dataset.where(:account_id => uuid).all.map{|row|
        row.values
      }
    end

    # Show status of the agent.
    def status
      node.nil? ? :offline : node.state
    end

    def to_hash
      super.merge({:status=>self.status})
    end

    def to_api_document(api_ver=nil)
      h = super()
      case api_ver
      when :v1112
        h.merge!(:status=>self.status)
        h.delete(:node_id)
      end
      h
    end

    # Returns total disk usage of associated volumes.
    def disk_usage
      volumes_dataset.lives.sum(:size).to_i
    end

    # Returns available space of the storage node.
    def free_disk_space
      self.offering_disk_space - self.disk_usage
    end

    # Check the free resource capacity across entire local VDC domain.
    def self.check_domain_capacity?(size, num=1)
      alives_size = Volume.dataset.lives.filter.sum(:size).to_i
      avail_size = self.online_nodes.sum(:offering_disk_space).to_i - alives_size
      
      (avail_size >= size * num.to_i)
    end
    
  end
end
