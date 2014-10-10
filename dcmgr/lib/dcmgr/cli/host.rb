# -*- coding: utf-8 -*-

require 'thor'
require 'isono'

module Dcmgr::Cli
class Host < Base
  namespace :host
  include Dcmgr::Models
  include Dcmgr::Constants::HostNode

  no_tasks {
    def self.common_options
      method_option :uuid, :type => :string, :desc => "The UUID for the new host node"
      method_option :display_name, :type => :string, :size => 255, :desc => "The name for the new host node"
      method_option :cpu_cores, :type => :numeric, :desc => "Number of cpu cores to be offered"
      method_option :memory_size, :type => :numeric, :desc => "Amount of memory to be offered (in MB)"
      method_option :hypervisor, :type => :string, :desc => "The hypervisor name. [#{SUPPORTED_HYPERVISOR.join(', ')}]"
      method_option :arch, :type => :string, :desc => "The CPU architecture type. [#{SUPPORTED_ARCH.join(', ')}]"
      option :disk_space, :type => :numeric, :desc => "Amount of disk space to store instances local volumes (MB)"
      option :scheduling_enabled, :type => :boolean, :desc => "Flag to tell scheduler to provision the host node"
    end

    def map_options_to_column
      optmap(options) { |c|
        c.map(:memory_size, :offering_memory_size)
        c.map(:cpu_cores, :offering_cpu_cores)
        c.map(:disk_space, :offering_disk_space_mb)
      }
    end
    private :map_options_to_column
  }

  desc "add NODE_ID [options]", "Register a new host node"
  method_option :force, :type => :boolean, :default=>false, :desc => "Force new entry creation"
  common_options
  method_options[:cpu_cores].default = 1
  method_options[:memory_size].default = 1024
  method_options[:hypervisor].default = 'kvm'
  method_options[:arch].default = 'x86_64'
  method_options[:disk_space].default = 0
  method_options[:scheduling_enabled].default = true
  def add(node_id)
    UnsupportedArchError.raise(options[:arch]) unless SUPPORTED_ARCH.member?(options[:arch])
    UnsupportedHypervisorError.raise(options[:hypervisor]) unless SUPPORTED_HYPERVISOR.member?(options[:hypervisor])

    unless (options[:force] || Isono::Models::NodeState.find(:node_id=>node_id))
      abort("Node ID is not registered yet: #{node_id}")
    end

    # :force is not field for HostNode model.
    options.delete(:force)

    fields = {
      :node_id => node_id,
    }.merge(map_options_to_column)
    fields.merge!({:uuid => options[:uuid]}) unless options[:uuid].nil?
    puts super(HostNode,fields)
  end

  desc "modify UUID [options]", "Modify a registered host node"
  method_option :node_id, :type => :string, :size => 255, :desc => "The node ID for the host node"
  common_options
  def modify(uuid)
    UnsupportedArchError.raise(options[:arch]) unless SUPPORTED_ARCH.member?(options[:arch])
    UnsupportedHypervisorError.raise(options[:hypervisor]) unless options[:hypervisor].nil? || SUPPORTED_HYPERVISOR.member?(options[:hypervisor])

    fields = map_options_to_column
    super(HostNode,uuid,fields)
  end

  desc "del UUID", "Deregister a host node"
  def del(uuid)
    super(HostNode,uuid)
  end

  no_tasks {
    include Dcmgr::Helpers
  }

  desc "show [UUID]", "Show list of host nodes and details"
  def show(uuid=nil)
    if uuid
      host = HostNode[uuid] || UnknownUUIDError.raise(uuid)
      puts ERB.new(<<__END, nil, '-').result(binding)
Host UUID: <%= host.canonical_uuid %>
Node ID: <%= host.node_id %>
CPU Cores (usage / offering): <%= host.cpu_core_usage %> / <%= host.offering_cpu_cores %> (<%= host.cpu_core_usage_percent.round(1) %>%)
Memory (usage / offering): <%= host.memory_size_usage %>MB / <%= host.offering_memory_size %>MB (<%= host.memory_size_usage_percent.round(1) %>%)
Disk Space (usage / offering): <%= ByteUnit.convert_to(host.disk_space_usage, ByteUnit::MB).round %>MB / <%= host.offering_disk_space_mb %>MB (<%= host.disk_space_usage_percent.round(1) %>%)
Hypervisor: <%= host.hypervisor %>
Architecture: <%= host.arch %>
Status: <%= host.status %>
Scheduling Enabled: <%= host.scheduling_enabled %>
Create: <%= host.created_at %>
Update: <%= host.updated_at %>
__END
    else
      ds = HostNode.dataset
      table = [['UUID', 'Node ID', 'Hypervisor', 'Architecture', 'Usage', 'Status', 'Scheduling']]
      ds.each { |r|
        table << [r.canonical_uuid, r.node_id, r.hypervisor, r.arch, "#{r.usage_percent}%", r.status, r.scheduling_enabled]
      }
      shell.print_table(table)
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
