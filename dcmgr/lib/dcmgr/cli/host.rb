# -*- coding: utf-8 -*-

require 'thor'
require 'isono'

module Dcmgr::Cli
class Host < Base
  namespace :host
  include Dcmgr::Models
  
  desc "add NODE_ID [options]", "Register a new host node"
  method_option :uuid, :type => :string, :desc => "The UUID for the new host node"
  method_option :name, :type => :string, :size => 255, :desc => "The name for the new host node"
  method_option :force, :type => :boolean, :default=>false, :desc => "Force new entry creation"
  method_option :cpu_cores, :type => :numeric, :default=>1, :desc => "Number of cpu cores to be offered"
  method_option :memory_size, :type => :numeric, :default=>1024, :desc => "Amount of memory to be offered (in MB)"
  method_option :hypervisor, :type => :string, :default=>'kvm', :desc => "The hypervisor name. [#{HostNode::SUPPORTED_HYPERVISOR.join(', ')}]"
  method_option :arch, :type => :string, :default=>'x86_64', :desc => "The CPU architecture type. [#{HostNode::SUPPORTED_ARCH.join(', ')}]"
  method_option :account_id, :type => :string, :default=>'a-shpoolxx', :desc => "The account ID to own this"
  def add(node_id)
    UnknownUUIDError.raise(options[:account_id]) if Account[options[:account_id]].nil?
    UnsupportedArchError.raise(options[:arch]) unless HostNode::SUPPORTED_ARCH.member?(options[:arch])
    UnsupportedHypervisorError.raise(options[:hypervisor]) unless HostNode::SUPPORTED_HYPERVISOR.member?(options[:hypervisor])

    unless (options[:force] || Isono::Models::NodeState.find(:node_id=>node_id))
      abort("Node ID is not registered yet: #{node_id}")
    end
    
    fields = {
              :name=>options[:name],
              :node_id=>node_id,
              :offering_cpu_cores=>options[:cpu_cores],
              :offering_memory_size=>options[:memory_size],
              :hypervisor=>options[:hypervisor],
              :arch=>options[:arch],
              :account_id=>options[:account_id],
    }
    fields.merge!({:uuid => options[:uuid]}) unless options[:uuid].nil?
    puts super(HostNode,fields)
  end
  
  desc "modify UUID [options]", "Modify a registered host node"
  method_option :name, :type => :string, :size => 255, :desc => "The name for the new host node"
  method_option :cpu_cores, :type => :numeric, :desc => "Number of cpu cores to be offered"
  method_option :account_id, :type => :string, :desc => "The account ID to own this"
  method_option :memory_size, :type => :numeric, :desc => "Amount of memory to be offered (in MB)"
  method_option :hypervisor, :type => :string, :desc => "The hypervisor name. [#{HostNode::SUPPORTED_HYPERVISOR.join(', ')}]"
  def modify(uuid)
    UnknownUUIDError.raise(options[:account_id]) if options[:account_id] && Account[options[:account_id]].nil?
    UnsupportedHypervisorError.raise(options[:hypervisor]) unless options[:hypervisor].nil? || HostNode::SUPPORTED_HYPERVISOR.member?(options[:hypervisor])
    fields = {
              :name=>options[:name],
              :offering_memory_size=>options[:memory_size],
              :offering_cpu_cores=>options[:cpu_cores],
              :account_id=>options[:account_id],
              :hypervisor=>options[:hypervisor]
    }
    super(HostNode,uuid,fields)
  end

  desc "del UUID", "Deregister a host node"
  def del(uuid)
    super(HostNode,uuid)
  end

  desc "show [UUID]", "Show list of host nodes and details"
  method_option :deleted, :type => :boolean, :default=>false, :desc => "Includes deleted host node entries"
  def show(uuid=nil)
    if uuid
      host = HostNode[uuid] || UnknownUUIDError.raise(uuid)
      puts ERB.new(<<__END, nil, '-').result(binding)
Host UUID: <%= host.canonical_uuid %>
Node ID: <%= host.node_id %>
CPU Cores (offerring): <%= host.offering_cpu_cores %>
Memory (offerring): <%= host.offering_memory_size %>MB
Hypervisor: <%= host.hypervisor %>
Architecture: <%= host.arch %>
Status: <%= host.status %>
Create: <%= host.created_at %>
Update: <%= host.updated_at %>
<%- if !host.deleted_at.nil? -%>
Deleted: <%= host.deleted_at %>
<%- end -%>
__END
    else
      cond = {}
      ds = if options[:deleted]
             HostNode.filter(cond)
           else
             HostNode.filter(cond).alives
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
Node ID              State
<%- nodes.each { |row| -%>
<%= "%-20s %-10s" % [row.node_id, row.state] %>
<%- } -%>
__END
  end
end
end
