# -*- coding: utf-8 -*-

require 'thor'
require 'isono'

module Dcmgr::Cli
class Host < Base
  namespace :host
  include Dcmgr::Models
  
  desc "add NODE_ID", "Register a new host pool node"
  method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new host pool."
  method_option :force, :type => :boolean, :aliases => "-f", :default=>false, :desc => "Force to create new entry."
  method_option :cpu_cores, :type => :numeric, :aliases => "-c", :default=>1, :desc => "Number of cpu cores to be offered."
  method_option :memory_size, :type => :numeric, :aliases => "-m", :default=>1000, :desc => "Amount of memory to be offered (in MB)."
  method_option :hypervisor, :type => :string, :aliases => "-p", :default=>'kvm', :desc => "The hypervisor name"
  method_option :arch, :type => :string, :aliases => "-r", :default=>'x86_64', :desc => "The CPU architecture type. [x86, x86_64]"
  method_option :account_id, :type => :string, :default=>'a-shpool', :aliases => "-a", :desc => "The account ID to own this."
  def add(node_id)
    unless HostPool::SUPPORTED_ARCH.member?(options[:arch])
      abort("Unsupported arch type: #{options[:arch]}")
    end

    unless (options[:force] == false && Isono::Models::NodeState.exists?(:node_id=>options[:node_id]))
      abort("Node ID is not registered yet: #{options[:node_id]}")
    end
    
    fields = {
              :node_id=>options[:node_id],
              :offering_cpu_cores=>options[:cpu_cores],
              :offering_memory_size=>options[:memory_size],
              :hypervisor=>options[:hypervisor],
              :arch=>options[:arch],
              :account_id=>options[:account_id],
    }
    fields.merge!({:uuid => options[:uuid]}) unless options[:uuid].nil?
    puts super(HostPool,fields)
  end

  desc "del UUID", "Deregister a host pool node"
  def del(uuid)
    hp = HostPool[uuid] || raise(Thor::Error.new("Unknown storage pool node: #{uuid}"))
    hp.delete
  end

  desc "shownodes", "Show node (agents)"
  def shownodes
    nodes = Isono::Models::NodeState.filter.all
    
    puts ERB.new(<<__END, nil, '-').result(binding)
Node ID\tState
<%- nodes.each { |row| -%>
<%= row.node_id %>\t<%= row.state %>
<%- } -%>
__END
  end
end
end
