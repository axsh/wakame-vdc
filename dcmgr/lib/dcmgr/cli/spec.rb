# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class Spec < Base
    namespace :spec
    M = Dcmgr::Models

    desc "add [options]", "Register a new machine spec"
    method_option :uuid, :type => :string, :desc => "The UUID for the new machine spec"
    method_option :account_id, :type => :string, :required => true, :desc => "The UUID of the account that this machine spec belongs to"
    method_option :arch, :type => :string, :default => 'x86_64', :desc => "The architecture for the new machine image. [#{M::HostNode::SUPPORTED_ARCH.join(', ')}]"
    method_option(:hypervisor, :type => :string, :default => M::HostNode::HYPERVISOR_KVM.to_s,
                  :desc => "The hypervisor type for the new instance. [#{M::HostNode::SUPPORTED_HYPERVISOR.join(', ')}]")
    method_option :cpu_cores, :type => :numeric, :default => 1, :desc => "The initial cpu cores for the new instance"
    method_option :memory_size, :type => :numeric, :default => 1024, :desc => "The memory size for the new instance"
    method_option :quota_weight, :type => :numeric, :default => 1.0, :desc => "The cost weight factor for the new instance"
    def add
      UnsupportedArchError.raise(options[:arch]) unless M::HostNode::SUPPORTED_ARCH.member?(options[:arch])
      UnsupportedHypervisorError.raise(options[:hypervisor]) unless M::HostNode::SUPPORTED_HYPERVISOR.member?(options[:hypervisor])
      uuid = super(M::InstanceSpec,options)
      # add one interface as default
      addvif(uuid, 'eth0')
      adddrive(uuid, 'local', 'ephemeral1')
      puts uuid
    end

    desc "modify UUID [options]", "Modify an existing machine spec"
    method_option :account_id, :type => :string, :desc => "The UUID of the account that this machine spec belongs to"
    method_option :arch, :type => :string, :desc => "The architecture for the new machine image. [#{M::HostNode::SUPPORTED_ARCH.join(', ')}]"
    method_option(:hypervisor, :type => :string,
                  :desc => "The hypervisor type for the new instance. [#{M::HostNode::SUPPORTED_HYPERVISOR.join(', ')}]")
    method_option :cpu_cores, :type => :numeric, :desc => "The initial cpu cores for the new instance"
    method_option :memory_size, :type => :numeric, :desc => "The memory size for the new instance"
    method_option :quota_weight, :type => :numeric, :desc => "The cost weight factor for the new instance"
    def modify(uuid)
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
  [<%= i[:index] %>] <%= name %>:
    Bandwidth: <%= i[:bandwidth] %> kbps
  <%- } -%>
<%- end -%>
<%- unless spec.drives.empty? -%>
Drives:
  <%- spec.drives.each { |name, i| -%>
  [<%= i[:index] %>] <%= name %>:
    Type: <%= i[:type] %>
    <%- if i[:size] -%>
    Size: <%= i[:size] %> MB
    <%- else -%>
    Snapshot ID: <%= i[:snapshot_id] %>
    <%- end -%>
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
      spec = M::InstanceSpec[uuid] || UnknownUUIDError.raise(uuid)

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
      spec = M::InstanceSpec[uuid] || UnknownUUIDError.raise(uuid)
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

    desc "adddrive UUID TYPE NAME", "Add drive (TYPE=local,volume)"
    method_option :index, :type => :numeric, :desc => "The index value for the interface. (>=0)"
    method_option :size, :type => :numeric, :default=>100, :desc => "Size of the drive. (MB)"
    def adddrive(uuid, type, name)
      spec = M::InstanceSpec[uuid] || UnknownUUIDError.raise(uuid)

      index = if options[:index].nil?
                # find max index value.
                index = spec.drives.values.map { |i| i[:index] }.max
                index.nil? ? 0 : (index + 1)
              else
                options[:index].to_i
              end

      case type
      when 'local'
        spec.add_local_drive(name, index, options[:size].to_i)
      when 'volume'
        spec.add_volume_drive(name, index, options[:size].to_i)
      else
        raise "Unknown drive type: #{type}"
      end

      spec.save
    end

    desc "deldrive UUID name", "Delete drive"
    def deldrive(uuid, name)
      spec = M::InstanceSpec[uuid] || UnknownUUIDError.raise(uuid)
      spec.remove_drive(name)
      spec.save
    end

    desc "modifydrive UUID name [options]", "Modify drive parameters"
    method_option :index, :type => :numeric, :desc => "The index value for the interface"
    method_option :size, :type => :numeric, :desc => "Size of the drive. (MB)"
    method_option :snapshot_id, :type => :string, :desc => "Snapshot ID to copy the content for new drive. Only for "
    def modifydrive(uuid, name)
      spec = M::InstanceSpec[uuid] || UnknownUUIDError.raise(uuid)
      if options[:index]
        spec.update_drive_index(name, options[:index].to_i)
      end
      if options[:size]
        spec.update_drive_size(name, options[:size].to_i)
      end
      if options[:snapshot_id]
        spec.update_drive_snapshot_id(name, options[:snapshot_id])
      end
      spec.save
    end

  end
end
