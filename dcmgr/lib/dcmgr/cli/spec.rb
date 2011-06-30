# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class Spec < Base
    namespace :spec
    M = Dcmgr::Models

    desc "add [options]", "Register a new machine spec"
    method_option :uuid, :type => :string, :aliases => "-u", :desc => "The UUID for the new machine spec"
    method_option :account_id, :type => :string, :aliases => "-a", :required => true, :desc => "The UUID of the account that this machine spec belongs to"
    method_option :arch, :type => :string, :default => 'x86_64', :aliases => "-r", :desc => "The architecture for the new machine image. [#{M::HostPool::SUPPORTED_ARCH.join(', ')}]"
    method_option(:hypervisor, :type => :string, :aliases => "-p", :default => M::HostPool::HYPERVISOR_KVM.to_s,
                  :desc => "The hypervisor type for the new instance. [#{M::HostPool::SUPPORTED_HYPERVISOR.join(', ')}]")
    method_option :cpu_cores, :type => :numeric, :aliases => "-c", :default => 1, :desc => "The initial cpu cores for the new instance"
    method_option :memory_size, :type => :numeric, :aliases => "-m", :default => 1024, :desc => "The memory size for the new instance"
    method_option :quota_weight, :type => :numeric, :aliases => "-w", :default => 1.0, :desc => "The cost weight factor for the new instance"
    def add
      UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?
      UnsupportedArchError.raise(options[:arch]) unless M::HostPool::SUPPORTED_ARCH.member?(options[:arch])
      UnsupportedHypervisorError.raise(options[:hypervisor]) unless M::HostPool::SUPPORTED_HYPERVISOR.member?(options[:hypervisor])
      fields = options.dup
      fields[:config] = {
      }
      puts super(M::InstanceSpec, fields)
    end
    
    desc "modify UUID [options]", "Modify an existing machine spec"
    method_option :account_id, :type => :string, :aliases => "-a", :desc => "The UUID of the account that this machine spec belongs to"
    method_option :arch, :type => :string, :aliases => "-r", :desc => "The architecture for the new machine image. [#{M::HostPool::SUPPORTED_ARCH.join(', ')}]"
    method_option(:hypervisor, :type => :string, :aliases => "-p",
                  :desc => "The hypervisor type for the new instance. [#{M::HostPool::SUPPORTED_HYPERVISOR.join(', ')}]")
    method_option :cpu_cores, :type => :numeric, :aliases => "-c", :desc => "The initial cpu cores for the new instance"
    method_option :memory_size, :type => :numeric, :aliases => "-m", :desc => "The memory size for the new instance"
    method_option :quota_weight, :type => :numeric, :aliases => "-w", :desc => "The cost weight factor for the new instance"
    def modify(uuid)
      UnknownUUIDError.raise(options[:account_id]) if options[:account_id] && M::Account[options[:account_id]].nil?
      UnsupportedArchError.raise(options[:arch]) unless options[:arch].nil? || M::HostPool::SUPPORTED_ARCH.member?(options[:arch])
      UnsupportedHypervisorError.raise(options[:hypervisor]) unless options[:hypervisor].nil? || M::HostPool::SUPPORTED_HYPERVISOR.member?(options[:hypervisor])
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
        spec = M::InstanceSpec[uuid]
        print ERB.new(<<__END, nil, '-').result(binding)
UUID:
  <%= spec.canonical_uuid %>
Account ID:
  <%= spec.account_id %>
Hypervisor:
  <%= spec.hypervisor %>
Arch:
  <%= spec.arch %>
CPU Cores:
  <%= spec.cpu_cores %>
Memory Size:
  <%= spec.memory_size %>
Quota Weight:
  <%= spec.quota_weight %>
Hypervisor Configuration:
  <%= spec.config.inspect %>
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
  end
end
