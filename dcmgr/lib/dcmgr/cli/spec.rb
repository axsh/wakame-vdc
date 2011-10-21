# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class Spec < Base
    namespace :spec
    M = Dcmgr::Models

    desc "add [options]", "Register a new machine spec"
    method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new machine spec"
    method_option :account_id, :type => :string, :aliases => "-a", :required => true, :desc => "The UUID of the account that this machine spec belongs to"
    method_option :arch, :type => :string, :default => 'x86_64', :aliases => "-r", :desc => "The architecture for the new machine image. [#{M::HostNode::SUPPORTED_ARCH.join(', ')}]"
    method_option(:hypervisor, :type => :string, :aliases => "-p", :default => M::HostNode::HYPERVISOR_KVM.to_s,
                  :desc => "The hypervisor type for the new instance. [#{M::HostNode::SUPPORTED_HYPERVISOR.join(', ')}]")
    method_option :cpu_cores, :type => :numeric, :aliases => "-c", :default => 1, :desc => "The initial cpu cores for the new instance"
    method_option :memory_size, :type => :numeric, :aliases => "-m", :default => 1024, :desc => "The memory size for the new instance"
    method_option :quota_weight, :type => :numeric, :aliases => "-w", :default => 1.0, :desc => "The cost weight factor for the new instance"
    def add
      UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?
      UnsupportedArchError.raise(options[:arch]) unless M::HostNode::SUPPORTED_ARCH.member?(options[:arch])
      UnsupportedHypervisorError.raise(options[:hypervisor]) unless M::HostNode::SUPPORTED_HYPERVISOR.member?(options[:hypervisor])
      uuid = super(M::InstanceSpec,options)
      # add one interface as default
      invoke("addvif", [uuid, 'eth0'])
      puts uuid
    end
    
    desc "modify UUID [options]", "Modify an existing machine spec"
    method_option :account_id, :type => :string, :aliases => "-a", :desc => "The UUID of the account that this machine spec belongs to"
    method_option :arch, :type => :string, :aliases => "-r", :desc => "The architecture for the new machine image. [#{M::HostNode::SUPPORTED_ARCH.join(', ')}]"
    method_option(:hypervisor, :type => :string, :aliases => "-p",
                  :desc => "The hypervisor type for the new instance. [#{M::HostNode::SUPPORTED_HYPERVISOR.join(', ')}]")
    method_option :cpu_cores, :type => :numeric, :aliases => "-c", :desc => "The initial cpu cores for the new instance"
    method_option :memory_size, :type => :numeric, :aliases => "-m", :desc => "The memory size for the new instance"
    method_option :quota_weight, :type => :numeric, :aliases => "-w", :desc => "The cost weight factor for the new instance"
    def modify(uuid)
      UnknownUUIDError.raise(options[:account_id]) if options[:account_id] && M::Account[options[:account_id]].nil?
      UnsupportedArchError.raise(options[:arch]) unless options[:arch].nil? || M::HostNode::SUPPORTED_ARCH.member?(options[:arch])
      UnsupportedHypervisorError.raise(options[:hypervisor]) unless options[:hypervisor].nil? || M::HostNode::SUPPORTED_HYPERVISOR.member?(options[:hypervisor])
      super(M::InstanceSpec,uuid,options)
    end
    
    desc "del UUID", "Delete registered machine spec"
    def del(uuid)
      UnknownUUIDError.raise(uuid) if M::InstanceSpec[uuid].nil?
      super(M::InstanceSpec, uuid)
    end

    desc "show [UUID]", "Show list of machine spec and details"
    def show(uuid=nil)
      if uuid
        spec = M::InstanceSpec[uuid] || UnknownUUIDError.raise(uuid)
        print ERB.new(<<__END, nil, '-').result(binding)
UUID: <%= spec.canonical_uuid %>
Account ID: <%= spec.account_id %>
Hypervisor: <%= spec.hypervisor %>
Arch: <%= spec.arch %>
CPU Cores: <%= spec.cpu_cores %>
Memory Size: <%= spec.memory_size %>
Quota Weight: <%= spec.quota_weight %>
<%- unless spec.vifs.empty? -%>
Interfaces:
  <%- spec.vifs.each { |name, i| -%>
  <%= name %>:
    Index: <%= i[:index] %>
    Bandwidth: <%= i[:bandwidth] %> kbps
  <%- } -%>
<%- end -%>
<%- unless spec.config.empty? -%>
Hypervisor Configuration:
  <%= spec.config.inspect %>
<%- end -%>
__END
      else
        cond = {}
        specs = M::InstanceSpec.filter(cond).all
        print ERB.new(<<__END, nil, '-').result(binding)
<%- specs.each { |row| -%>
<%= "%-20s  %-15s %-15s" % [row.canonical_uuid, row.account_id, row.arch] %>
<%- } -%>
__END
      end
    end
    
    desc "addvif UUID name", "Add interfance"
    method_option :index, :type => :numeric, :desc => "The index value for the interface. (>=0)"
    method_option :bandwidth, :type => :numeric, :default=>100000, :desc => "The bandwidth (kbps) of the interface"
    def addvif(uuid, name)
      spec = M::InstanceSpec[uuid]

      index = if options[:index].nil?
                # find max index value.
                index = spec.vifs.values.map { |i| i[:index] }.max
                index.nil? ? 0 : (index + 1)
              else
                options[:index].to_i
              end
      
      spec.add_vif(name, index.to_i, options[:bandwidth].to_i)
      spec.save
    end
    
    desc "delvif UUID name", "Delete interfance"
    def delvif(uuid, name)
      spec = M::InstanceSpec[uuid]
      spec.remove_vif(name)
      spec.save
    end
    
    desc "modifyvif UUID name [options]", "Modify interfance parameters"
    method_option :index, :type => :numeric, :desc => "The index value for the interface"
    method_option :bandwidth, :type => :numeric, :desc => "The bandwidth (kbps) of the interface"
    def modifyvif(uuid, name)
      spec = M::InstanceSpec[uuid]
      if options[:index]
        spec.update_vif_index(name, options[:index].to_i)
      end
      if options[:bandwidth]
        spec.update_vif_bandwidth(name, options[:bandwidth].to_i)
      end
      spec.save
    end
  end
end
