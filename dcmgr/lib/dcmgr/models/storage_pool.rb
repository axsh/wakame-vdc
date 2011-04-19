# -*- coding: utf-8 -*-
require 'statemachine'

module Dcmgr::Models
  class StoragePool < AccountResource
    taggable 'sp'
    with_timestamps

    STATAS_TYPE_REGISTERING = "registering"
    STATAS_TYPE_ONLINE = "online"
    STATAS_TYPE_DEGRADE = "degrade"
    STATAS_TYPE_FAILED = "failed"
    STATAS_TYPE_DEREGISTERED = "deregistered"

    STATUS_MSGS = {
      STATAS_TYPE_REGISTERING => :registering,
      STATAS_TYPE_ONLINE => :online,
      STATAS_TYPE_DEGRADE => :degrade,
      STATAS_TYPE_FAILED => :failed,
      STATAS_TYPE_DEREGISTERED => :deregistered
    }
    
    inheritable_schema do
      String :node_id, :null=>false
      String :export_path, :null=>false
      String :status, :null=>false, :default=>STATAS_TYPE_REGISTERING
      Fixnum :offering_disk_space, :null=>false, :unsigned=>true
      String :transport_type, :null=>false
      String :storage_type, :null=>false
      String :ipaddr, :null=>false
      String :snapshot_base_path, :null=>false

      index :node_id
    end

    one_to_many :volumes
    one_to_many :volume_snapshots
    
    many_to_one :storage_agents
    
    def before_validation
      export_path = self.export_path
      if export_path =~ /^(\/[a-z0-9]+)+$/
        export_path = export_path.split('/')
        export_path.shift
        self.export_path = export_path.join('/')
      end
    end

    def state_machine
      model = self
      st = Statemachine.build do
        superstate :storage_condition do
          trans :registering, :on_success, :online
          trans :registering, :on_error, :degrade
          trans :online, :on_success, :online
          trans :online, :on_error, :degrade
          trans :degrade, :on_success, :online
          trans :degrade, :on_error, :degrade

          event :on_fail, :failed
          event :on_deregistered, :deregistered
        end

        trans :failed, :on_success, :online
        trans :failed, :on_error, :degrade
        trans :failed, :on_deregistered, :deregistered

        on_entry_of :registering, proc {
          model.status = STATAS_TYPE_REGISTERING
        }

        on_entry_of :online, proc {
          model.status = STATAS_TYPE_ONLINE
        }

        on_entry_of :degrade, proc {
          model.status = STATAS_TYPE_DEGRADE
        }

        on_entry_of :failed, proc {
          model.status = STATAS_TYPE_FAILED
        }

        on_entry_of :deregistered, proc {
          model.status = STATAS_TYPE_DEREGISTERED
        }
      end

      if self[:status]
        if st.has_state(STATUS_MSGS[self[:status]].to_sym)
          st.state = STATUS_MSGS[self[:status]].to_sym
        else
          raise "Unknown state: #{self[:status]}"
        end
      else
        st.reset
      end
      st
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

    # def find_private_pool(account_id, uuid)
    #   sp = self.dataset.where(:account_id=>account_id).where(:uuid=>uuid)
    # end

    def create_volume(account_id, size, snapshot_id=nil)
      v = Volume.create(:account_id => account_id,
                        :storage_pool_id => self.id,
                        :snapshot_id => snapshot_id,
                        :size =>size)
    end
  end
end
