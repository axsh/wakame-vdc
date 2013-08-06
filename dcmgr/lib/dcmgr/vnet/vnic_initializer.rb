# -*- coding: utf-8 -*-

module Dcmgr::VNet::VNicInitializer
  def self.included klass
    klass.class_eval do
      include Dcmgr::VNet::SGHandlerCommon
    end
  end
  M = Dcmgr::Models

  def init_vnic(vnic_id)
    vnic = M::NetworkVif[vnic_id]
    raise "Vnic '#{vnic.canonical_uuid}' not attached to an instance." if vnic.instance.nil?
    raise "Vnic '#{vnic.canonical_uuid}' is not on a host node." if vnic.instance.host_node.nil?
    host_node = vnic.instance.host_node

    init_vnic_on_host(host_node, vnic)

    vnic.security_groups.each { |group|
      group.online_host_nodes.each { |host_node|
        host_didnt_have_secg_yet = group.network_vif_dataset.filter(:instance => host_node.instances_dataset).exclude(:instance => vnic.instance).empty?

        if host_didnt_have_secg_yet
          init_security_group(host_node, group)
        else
          update_isolation_group(host_node, group)
        end
      }
    }

    # We refresh the references after all security groups have been initialized.
    # Otherwise it's possible that a group's referencee's will be updated before
    # the group is initialized, resulting in faulty rules.
    vnic.security_groups.each {|group| refresh_referencers(group)}

    set_vnic_security_groups(host_node, vnic)

    nil # Returning nil to simulate a void method
  end
end