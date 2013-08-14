# -*- coding: utf-8 -*-

module Dcmgr::VNet::SGHandler
  def self.included klass
    klass.class_eval do
      include Dcmgr::VNet::SGHandlerCommon
    end
  end
  M = Dcmgr::Models

  # This is called when a hva host is restarted. Service netfilter itself
  # will ask sg_handler to initialize all of its vnics.
  def init_host(node_id)
    host = M::HostNode.find(:node_id => node_id) || raise("Couldn't find a host node with id: '#{node_id}'.")
    logger.info "Telling host '#{host.canonical_uuid}' to initialize all its vnics and their security groups."

    host.security_groups.each { |sg|
      pf.init_security_group(host, sg)
    }

    host.alive_vnics.each { |vnic|
      pf.init_vnic_on_host(host, vnic)
      pf.set_vnic_security_groups(host, vnic)
    }

    commit_changes
  end

  def add_sgs_to_vnic(vnic_id, sg_uuids)
    logger.info "Adding vnic: '#{vnic_id}' to security groups '#{sg_uuids.join(", ")}'"
    vnic = M::NetworkVif[vnic_id]
    vnic_host = vnic.instance.host_node

    current_sg_uuids = vnic.security_groups.map { |g| g.canonical_uuid }
    new_sg_uuids = sg_uuids - current_sg_uuids

    new_sg_uuids.each { |group_id|
      group = M::SecurityGroup[group_id]
      hosts_before_change = group.online_host_nodes
      vnic.add_security_group(group)

      hosts_before_change.each { |host_node|
        pf.update_isolation_group(host_node, group)
      }

      pf.init_security_group(vnic_host, group) unless hosts_before_change.member?(vnic_host)

      pf.refresh_referencers(group)
    }

    pf.set_vnic_security_groups(vnic_host, vnic)

    commit_changes
  end

  def remove_sgs_from_vnic(vnic_id, sg_ids_to_remove)
    logger.info "Removing vnic: '#{vnic_id}' from security groups '#{sg_ids_to_remove.join(", ")}'"
    vnic = M::NetworkVif[vnic_id]
    vnic_host = vnic.instance.host_node

    current_sg_ids = vnic.security_groups.map { |g| g.canonical_uuid }
    pf.set_vnic_security_groups(vnic_host, vnic, current_sg_ids - sg_ids_to_remove)

    (sg_ids_to_remove & current_sg_ids).each { |group_id|
      group = M::SecurityGroup[group_id]
      vnic.remove_security_group(group)

      group.online_host_nodes.each { |host_node|
        pf.update_isolation_group(host_node, group)
        pf.handle_referencees(host_node, group)
      }

      pf.destroy_security_group(vnic_host, group_id) unless group.online_host_nodes.member?(vnic_host)

      pf.refresh_referencers(group)
    }
    commit_changes
  end

  def destroy_vnic(vnic_id, update_database = false)
    vnic = M::NetworkVif[vnic_id]
    raise "Vnic '#{vnic.canonical_uuid}' not attached to an instance." if vnic.instance.nil?
    raise "Vnic '#{vnic.canonical_uuid}' is not on a host node." if vnic.instance.host_node.nil?
    host_node = vnic.instance.host_node
    pf.destroy_vnic_on_host(host_node, vnic)

    vnic.security_groups.each { |group|
      group_id = group.canonical_uuid

      group.online_host_nodes.each { |host_node|
        no_more_vnics_left_in_group = group.network_vif_dataset.filter(:instance => host_node.instances_dataset).exclude(:instance => vnic.instance).empty?

        if no_more_vnics_left_in_group
          pf.destroy_security_group(host_node, group_id)
        else
          # The vnic isn't destroyed in the database until later.
          # Therefore we delete it from the ips we pass to the isolation group.
          self_ips = vnic.direct_ip_lease.map { |lease| lease.ipv4_s }
          pf.update_isolation_group(host_node, group, group.vnic_ips - self_ips)
          pf.refresh_referencers(group, vnic)
        end
      }

    }

    # Some time we might want to destroy the vnic in this method so the next
    # security group update isn't called inbetween this method and the actual
    # vnic destruction.
    vnic.destroy if update_database

    commit_changes
  end

  def update_sg_rules(secg_id)
    group = M::SecurityGroup[secg_id]
    rules = group.rules_array_no_ref

    group.online_host_nodes.each { |host_node|
      logger.info "Updating rules of group '#{secg_id}' on host '#{host_node.canonical_uuid}'"
      pf.update_secg_rules(host_node, group)
      pf.handle_referencees(host_node, group)
    }

    commit_changes
  end
end
