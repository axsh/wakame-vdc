# -*- coding: utf-8 -*-

module Dcmgr::VNet::SGHandler
  M = Dcmgr::Models

  def init_vnic(vnic_id)
    #TODO: Nilchecks for instance and host node
    vnic = M::NetworkVif[vnic_id]
    host_node = vnic.instance.host_node
    tasks = []

    logger.info "Telling host '#{host_node.canonical_uuid}' to initialize vnic '#{vnic_id}'."
    call_packetfilter_service(host_node,"init_vnic",vnic_id,tasks)

    add_sgs_to_vnic(vnic_id,vnic.security_groups.map {|sg| sg.canonical_uuid})

    nil # Returning nil to simulate a void method
  end

  def add_sgs_to_vnic(vnic_id,sg_uuids)
    logger.info "Adding vnic: '#{vnic_id}' to security groups '#{sg_uuids.join(",")}'"
    vnic = M::NetworkVif[vnic_id]
    groups = sg_uuids.map {|sgid| M::SecurityGroup[sgid]}

    groups.each {|group|
      group_id = group.canonical_uuid
      group.host_nodes.each {|host_node|
        # Check if the host node had this vnic's security groups yet
        query = group.network_vif_dataset.filter(:instance => host_node.instances_dataset).exclude(:instance => vnic.instance)
        if query.empty?
          logger.debug "Host '#{host_node.canonical_uuid}' doesn't have security group '#{group.canonical_uuid}' yet. Initialize it."

          sec_tasks = [] # These will be the rules in this security group
          call_packetfilter_service(host_node,"init_security_group",group_id,sec_tasks)

          iso_tasks = [] # These will be isolation rules for all vnics in the group
          call_packetfilter_service(host_node,"init_isolation_group",group_id,iso_tasks)
        else
          logger.debug "Host '#{host_node.canonical_uuid}' already has security group '#{group.canonical_uuid}'. Update its isolation."
          tasks = [] # Create the isolation tasks for all vnics in this group
          call_packetfilter_service(host_node,"update_isolation_group",group_id,tasks)
        end
      }
    }
    nil # Returning nil to simulate a void method
  end

  def remove_sgs_from_vnic(vnic_id,sg_uuids)
    logger.info "Removing vnic: '#{vnic_id}' from security groups '#{sg_uuids.join(",")}'"
    nil # Returning nil to simulate a void method
  end

  def destroy_vnic(vnic_id)
    host_node = M::NetworkVif[vnic_id].instance.host_node
    logger.info "Telling host '#{host_node.canonical_uuid}' to destroy vnic '#{vnic_id}'."
    call_packetfilter_service(host_node,"destroy_vnic",vnic_id)

    vnic = M::NetworkVif[vnic_id]
    vnic.security_groups.each { |group|
      group_id = group.canonical_uuid
      group.host_nodes.each {|host_node|
        # Check if the host node had this vnic's security groups yet
        query = group.network_vif_dataset.filter(:instance => host_node.instances_dataset).exclude(:instance => vnic.instance)
        if query.empty?
          logger.debug "Host '#{host_node.canonical_uuid}' no longer has security group '#{group.canonical_uuid}' yet. Destroy it."

          call_packetfilter_service(host_node,"destroy_security_group",group_id)
          call_packetfilter_service(host_node,"destroy_isolation_group",group_id)
        else
          logger.debug "Host '#{host_node.canonical_uuid}' still has security group '#{group.canonical_uuid}'. Update its isolation."
          tasks = [] # Create the isolation tasks for all vnics in this group
          call_packetfilter_service(host_node,"update_isolation_group",group_id,tasks)
        end
      }
    }

    nil # Returning nil to simulate a void method
  end

  def call_packetfilter_service(host_node,method,*args)
    raise NotImplementedError
  end

end
