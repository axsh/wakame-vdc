# -*- coding: utf-8 -*-

module Dcmgr::VNet::SGHandler
  M = Dcmgr::Models
  # All methods in this module return nil. That's to prevent them from returning
  # Sequel models to classes that might not have access to the database, which
  # would make them crash.

  # Initialized an entire host.
  # This is called when a hva host is restarted. Service netfilter itself
  # will ask sg_handler to initialize all of its vnics.
  def init_host(node_id)
    host = M::HostNode.find(:node_id => node_id) || raise("Couldn't find a host node with id: '#{node_id}'.")
    host_id = host.canonical_uuid
    logger.info "Telling host '#{host_id}' to initialize all its vnics and their security groups."
    host.security_groups.each { |sg|
      group_id = sg.canonical_uuid
      logger.debug "Initializing security group #{group_id}"
      call_packetfilter_service(host,"init_security_group",group_id,[])
      friend_ips = sg.network_vif.map {|vif| vif.direct_ip_lease.first.ipv4 }
      call_packetfilter_service(host_node,"init_isolation_group",group_id,friend_ips)
    }

    host.alive_vnics.each { |vnic|
      vnic_id = vnic.canonical_uuid
      group_ids = vnic.security_groups.map {|sg| sg.canonical_uuid}
      call_packetfilter_service(host,"init_vnic",vnic_id,[])
      call_packetfilter_service(host,"set_vnic_security_groups",vnic_id,group_ids)
    }

    nil # Returning nil to simulate a void method
  end

  def init_vnic(vnic_id)
    vnic = M::NetworkVif[vnic_id]
    raise "Vnic '#{vnic.canonical_uuid}' not attached to an instance." if vnic.instance.nil?
    raise "Vnic '#{vnic.canonical_uuid}' is not on a host node." if vnic.instance.host_node.nil?
    host_node = vnic.instance.host_node
    tasks = []

    logger.info "Telling host '#{host_node.canonical_uuid}' to initialize vnic '#{vnic_id}'."
    call_packetfilter_service(host_node,"init_vnic",vnic_id,tasks)

    group_ids = []
    vnic.security_groups.each {|group|
      group_id = group.canonical_uuid
      friend_ips = group.network_vif.map {|vif| vif.direct_ip_lease.first.ipv4 }
      group_ids << group_id

      group.host_nodes.each {|host_node|
        # Check if the host node had this vnic's security groups yet
        query = group.network_vif_dataset.filter(:instance => host_node.instances_dataset).exclude(:instance => vnic.instance)
        if query.empty?
          logger.debug "Host '#{host_node.canonical_uuid}' doesn't have security group '#{group.canonical_uuid}' yet. Initialize it."

          sec_tasks = [] # These will be the rules in this security group
          call_packetfilter_service(host_node,"init_security_group",group_id,sec_tasks)
          call_packetfilter_service(host_node,"init_isolation_group",group_id,friend_ips)
        else
          logger.debug "Host '#{host_node.canonical_uuid}' already has security group '#{group.canonical_uuid}'. Update its isolation."
          call_packetfilter_service(host_node,"update_isolation_group",group_id,friend_ips)
        end
      }
    }
    logger.debug "Set security groups '#{group_ids}' for vnic '#{vnic_id}'."
    call_packetfilter_service(host_node,"set_vnic_security_groups",vnic_id,group_ids)

    nil # Returning nil to simulate a void method
  end

  def add_sgs_to_vnic(vnic_id,sg_uuids)
    logger.info "Adding vnic: '#{vnic_id}' to security groups '#{sg_uuids.join(",")}'"
    vnic = M::NetworkVif[vnic_id]
    vnic_host = vnic.instance.host_node

    host_had_secg_already = false
    current_sgids = vnic.security_groups.map {|g| g.canonical_uuid }
    sg_uuids.each { |group_id|
      if current_sgids.member?(group_id)
        logger.warn "Vnic '#{vnic_id}' is already in security group '#{group_id}'."
        next
      end
      group = M::SecurityGroup[group_id]
      friend_ips = group.network_vif.map {|vif| vif.direct_ip_lease.first.ipv4 }

      group.host_nodes.each {|host_node|
        friend_ips = group.network_vif.map {|vif| vif.direct_ip_lease.first.ipv4 }
        call_packetfilter_service(host_node,"update_isolation_group",group_id,friend_ips)

        host_had_secg_already = true if host_node == vnic_host
      }

      unless host_had_secg_already
        sec_tasks = []
        call_packetfilter_service(vnic_host,"init_security_group",group_id,sec_tasks)
        call_packetfilter_service(vnic_host,"init_isolation_group",group_id,friend_ips)
      end
      vnic.add_security_group(group)
    }
    call_packetfilter_service(vnic_host,"set_vnic_security_groups",vnic_id,(sg_uuids + current_sgids).uniq)

    nil # Returning nil to simulate a void method
  end

  def remove_sgs_from_vnic(vnic_id,sg_uuids)
    logger.info "Removing vnic: '#{vnic_id}' from security groups '#{sg_uuids.join(",")}'"
    vnic = M::NetworkVif[vnic_id]
    vnic_host = vnic.instance.host_node

    host_had_secg_already = false
    current_sgids = vnic.security_groups.map {|g| g.canonical_uuid }
    sg_uuids.each { |group_id|
      if vnic.security_groups_dataset.filter(:uuid => M::SecurityGroup.trim_uuid(group_id)).empty?
        logger.warn "Vnic '#{vnic_id}' isn't in security group '#{group_id}'."
        next
      end
      group = M::SecurityGroup[group_id]
      vnic.remove_security_group(group)

      host_had_secg_already = false
      friend_ips = group.network_vif.map {|vif| vif.direct_ip_lease.first.ipv4 }
      group.host_nodes.each {|host_node|
        call_packetfilter_service(host_node,"update_isolation_group",group_id,friend_ips)

        host_had_secg_already = true if host_node == vnic_host
      }

      unless host_had_secg_already
        call_packetfilter_service(vnic_host,"destroy_security_group",group_id)
        call_packetfilter_service(vnic_host,"destroy_isolation_group",group_id)
      end
    }
    call_packetfilter_service(vnic_host,"set_vnic_security_groups",vnic_id,(current_sgids - sg_uuids))
    nil # Returning nil to simulate a void method
  end

  def destroy_vnic(vnic_id)
    vnic = M::NetworkVif[vnic_id]
    raise "Vnic '#{vnic.canonical_uuid}' not attached to an instance." if vnic.instance.nil?
    raise "Vnic '#{vnic.canonical_uuid}' is not on a host node." if vnic.instance.host_node.nil?
    host_node = vnic.instance.host_node
    logger.info "Telling host '#{host_node.canonical_uuid}' to destroy vnic '#{vnic_id}'."
    call_packetfilter_service(host_node,"destroy_vnic",vnic_id)

    vnic.security_groups.each { |group|
      group_id = group.canonical_uuid
      friend_ips = group.network_vif.map {|vif| vif.direct_ip_lease.first.ipv4 }
      group.host_nodes.each {|host_node|
        # Check if the host node had this vnic's security groups yet
        query = group.network_vif_dataset.filter(:instance => host_node.instances_dataset).exclude(:instance => vnic.instance)
        if query.empty?
          logger.debug "Host '#{host_node.canonical_uuid}' no longer has security group '#{group.canonical_uuid}' yet. Destroy it."

          call_packetfilter_service(host_node,"destroy_security_group",group_id)
          call_packetfilter_service(host_node,"destroy_isolation_group",group_id)
        else
          logger.debug "Host '#{host_node.canonical_uuid}' still has security group '#{group.canonical_uuid}'. Update its isolation."
          call_packetfilter_service(host_node,"update_isolation_group",group_id,friend_ips)
        end
      }
    }

    nil # Returning nil to simulate a void method
  end

  def call_packetfilter_service(host_node,method,*args)
    raise NotImplementedError, "Classes that include the sg handler module must define a 'call_packetfilter_service(host_node,method,*args)' method"
  end
end
