# -*- coding: utf-8 -*-

require 'thor'
require 'isono'

module Dcmgr::Cli
class Storage < Base
  namespace :storage
  include Dcmgr::Models
  include Dcmgr::Constants::StorageNode

  class IscsiOperation < Base
    namespace :iscsi
    M = Dcmgr::Models

    def self.basename
      "#{super()} #{Storage.namespace} #{self.namespace}"
    end
    
    desc "add <node id> [options]", "Register a new ISCSI storage node"
    option :uuid, :type => :string, :desc => "The uuid for the new storage node"
    option :disk_space, :type => :numeric, :required => true, :desc => "Amount of disk size to be exported (in MB)"
    option :ipaddr, :type => :string, :required => true, :desc => "IP address of transport target"
    option :display_name, :type => :string, :size => 255, :desc => "The name for the new storage node"
    def add(node_id)
      fields = {
        :node_id=>node_id,
        :offering_disk_space_mb=>options[:disk_space],
        :ip_address=>options[:ipaddr],
        :display_name=>options[:display_name],
      }
      fields.merge!({:uuid => options[:uuid]}) unless options[:uuid].nil?
      
      say super(M::IscsiStorageNode,fields)
    end

    desc "modify <uuid> [options]", "Modify <uuid> of ISCSI storage node"
    option :node_id, :type => :string, :desc => "The node ID for the storage node"
    option :disk_space, :type => :numeric, :desc => "Amount of disk size to be exported (in MB)"
    option :ipaddr, :type => :string, :desc => "IP address of transport target"
    option :display_name, :type => :string, :size => 255, :desc => "The name for the new storage node"
    def modify(uuid)
      fields = {
        :node_id=>options[:node_id],
        :offering_disk_space_mb=>options[:disk_space],
        :ip_address=>options[:ipaddr],
        :display_name=>options[:display_name],
      }
      super(M::IscsiStorageNode,uuid,fields)
    end
  end

  desc "iscsi SUBCOMMAND [options]", "Operations for iscsi storage"
  subcommand :iscsi, IscsiOperation

  class NFSOperation < Base
    namespace :nfs
    M = Dcmgr::Models

    def self.basename
      "#{super()} #{Storage.namespace} #{self.namespace}"
    end
    
    desc "add <node id> [options]", "Register a new NFS storage node"
    option :uuid, :type => :string, :desc => "The uuid for the new storage node"
    option :disk_space, :type => :numeric, :required => true, :desc => "Amount of disk size to be exported (in MB)"
    option :display_name, :type => :string, :size => 255, :desc => "The name for the new storage node"
    option :mount_point, :type => :string, :size => 255, :desc => "Mount point path on host node"
    def add(node_id)
      fields = {
        :node_id=>node_id,
        :offering_disk_space_mb=>options[:disk_space],
        :display_name=>options[:display_name],
        :mount_point => options[:mount_point],
      }
      fields.merge!({:uuid => options[:uuid]}) unless options[:uuid].nil?

      say super(M::NfsStorageNode,fields)
    end

    desc "modify <uuid> [options]", "Modify <uuid> of NFS storage node"
    option :node_id, :type => :string, :desc => "The node ID for the storage node"
    option :disk_space, :type => :numeric, :desc => "Amount of disk size to be exported (in MB)"
    option :display_name, :type => :string, :size => 255, :desc => "The name for the new storage node"
    option :mount_point, :type => :string, :size => 255, :desc => "Mount point path on host node"
    def modify(uuid)
      fields = {
        :node_id=>options[:node_id],
        :offering_disk_space_mb=>options[:disk_space],
        :display_name=>options[:display_name],
        :mount_point => options[:mount_point],
      }
      # NfsStorageNode is a class table inheritance model. so applys
      # the find and update operation to the parent class.
      super(M::StorageNode,uuid,fields)
    end
  end

  desc "nfs SUBCOMMAND [options]", "Operations for NFS storage"
  subcommand :nfs, NFSOperation

  desc "del UUID", "Deregister a storage node"
  def del(uuid)
    super(StorageNode,uuid)
  end

  desc "show [UUID]", "Show list of storage nodes and details"
  def show(uuid=nil)
    if uuid
      st = StorageNode[uuid] || UnknownUUIDError.raise(uuid)
      puts ERB.new(<<__END, nil, '-').result(binding)
UUID: <%= st.canonical_uuid %>
Node ID: <%= st.node_id %>
Disk space (offerring): <%= st.offering_disk_space_mb %>MB
Storage Type: <%= st.storage_type %>
Create: <%= st.created_at %>
Update: <%= st.updated_at %>
__END
      case st
      when Dcmgr::Models::IscsiStorageNode
        puts <<__END
IP Address: #{st.ip_address}
__END
      end
    else
      ds = StorageNode.dataset
      table = [['UUID', 'Node ID', 'Storage', 'Status']]
      ds.each { |r|
        table << [r.canonical_uuid, r.node_id, r.storage_type, r.status]
      }
      shell.print_table(table)
    end
  end

  desc "shownodes", "Show node (agents)"
  def shownodes
    nodes = Isono::Models::NodeState.filter.all

    puts ERB.new(<<__END, nil, '-').result(binding)
<%- nodes.each { |row| -%>
<%= "%-20s %-10s" % [row.node_id, row.state] %>
<%- } -%>
__END
  end
end
end
