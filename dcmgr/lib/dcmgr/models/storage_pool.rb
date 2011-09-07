# -*- coding: utf-8 -*-

module Dcmgr::Models
  class StoragePool < AccountResource
    taggable 'sp'

    BACKINGSTORE_ZFS = 'zfs'
    BACKINGSTORE_RAW = 'raw'

    SUPPORTED_BACKINGSTORE = [BACKINGSTORE_ZFS, BACKINGSTORE_RAW]

    inheritable_schema do
      String :node_id, :null=>false
      String :export_path, :null=>false
      Fixnum :offering_disk_space, :null=>false, :unsigned=>true
      String :transport_type, :null=>false
      String :storage_type, :null=>false
      String :ipaddr, :null=>false
      String :snapshot_base_path, :null=>false

      index :node_id
    end
    with_timestamps

    one_to_many :volumes
    one_to_many :volume_snapshots
    
    many_to_one :node, :class=>Isono::Models::NodeState, :key=>:node_id, :primary_key=>:node_id
    
    def before_validation
      export_path = self.export_path
      if export_path =~ /^(\/[a-z0-9]+)+$/
        export_path = export_path.split('/')
        export_path.shift
        self.export_path = export_path.join('/')
      end
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

    def to_api_document
      h = super()
      h.merge!(:status=>self.status)
      h.delete(:node_id)
      h
    end
  end
end
