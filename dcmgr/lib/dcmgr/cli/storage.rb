# -*- coding: utf-8 -*-

require 'thor'
require 'isono'

module Dcmgr::Cli
class Storage < Base
  namespace :storage
  include Dcmgr::Models
  
  desc "add NODE_ID [options]", "Register a new storage node"
  method_option :uuid, :type => :string, :desc => "The uuid for the new storage node"
  method_option :base_path, :type => :string, :required => true, :desc => "Base path to store volume files"
  method_option :snapshot_base_path, :type => :string, :required => true, :desc => "Base path to store snapshot files"
  method_option :disk_space, :type => :numeric, :required => true, :desc => "Amount of disk size to be exported (in MB)"
  method_option :force, :type => :boolean, :default=>false, :desc => "Force new entry creation"
  method_option :transport_type, :type => :string, :default=>'iscsi', :desc => "Transport type [iscsi]"
  method_option :ipaddr, :type => :string, :required=>true, :desc => "IP address of transport target"
  method_option :storage_type, :type => :string, :default=>'zfs', :desc => "Storage type [#{StorageNode::SUPPORTED_BACKINGSTORE.join(', ')}]"
  method_option :account_id, :type => :string, :default=>'a-shpoolxx', :desc => "The account ID to own this"
  def add(node_id)
    unless (options[:force] || Isono::Models::NodeState.find(:node_id=>node_id))
      abort("Node ID is not registered yet: #{node_id}")
    end

    fields = {:node_id=>node_id,
              :offering_disk_space=>options[:disk_space],
              :transport_type=>options[:transport_type],
              :storage_type=>options[:storage_type],
              :export_path=>options[:base_path],
              :snapshot_base_path => options[:snapshot_base_path],
              :ipaddr=>options[:ipaddr],
              :account_id=>options[:account_id],
    }
    fields.merge!({:uuid => options[:uuid]}) unless options[:uuid].nil?
    
    puts super(StorageNode,fields)
  end

  desc "del UUID", "Deregister a storage node"
  def del(uuid)
    super(StorageNode,uuid)
  end

  desc "show [UUID]", "Show list of storage nodes and details"
  method_option :deleted, :type => :boolean, :default=>false, :desc => "Includes deleted storage node entries"
  def show(uuid=nil)
    if uuid
      st = StorageNode[uuid] || UnknownUUIDError.raise(uuid)
      puts ERB.new(<<__END, nil, '-').result(binding)
UUID: <%= st.canonical_uuid %>
Node ID: <%= st.node_id %>
Disk space (offerring): <%= st.offering_disk_space %>MB
Storage: <%= st.storage_type %>
Transport: <%= st.transport_type %>
IP Address: <%= st.ipaddr %>
Export path: <%= st.export_path %>
Snapshot base path: <%= st.snapshot_base_path %>
Create: <%= st.created_at %>
Update: <%= st.updated_at %>
<%- if !st.deleted_at.nil? -%>
Deleted: <%= st.deleted_at %>
<%- end -%>
__END
    else
      cond = {}
      ds = if options[:deleted]
             StorageNode.filter(cond)
           else
             StorageNode.filter(cond).alives
           end
      puts ERB.new(<<__END, nil, '-').result(binding)
<%= "%-15s %-20s %-10s %-10s" % ['UUID', 'Node ID', 'Status', 'Deleted'] %>
<%- ds.each { |row| -%>
<%= "%-15s %-20s %-10s %-10s" % [row.canonical_uuid, row.node_id, row.status, !row.deleted_at.nil? ] %>
<%- } -%>
__END
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
