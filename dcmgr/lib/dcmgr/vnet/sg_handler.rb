# -*- coding: utf-8 -*-

module Dcmgr::VNet::SGHandler
  M = Dcmgr::Models

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
      group_ids << group_id
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
    logger.debug "Set security groups '#{group_ids}'' for vnic '#{vnic_id}'."
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
      # no need to do anything if we're already in this group
      #TODO: Display warning for this
      next if current_sgids.member?(group_id)
      group = M::SecurityGroup[group_id]

      group.host_nodes.each {|host_node|
        tasks = []
        call_packetfilter_service(host_node,"update_isolation_group",group_id,tasks)

        #TODO: Handle referencers and referencees
        host_had_secg_already = true if host_node == vnic_host
      }

      unless host_had_secg_already
        sec_tasks = []
        call_packetfilter_service(vnic_host,"init_security_group",group_id,sec_tasks)
        iso_tasks = []
        call_packetfilter_service(vnic_host,"init_isolation_group",group_id,iso_tasks)
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
      next if vnic.security_groups_dataset.filter(:uuid => M::SecurityGroup.trim_uuid(group_id)).empty?
      group = M::SecurityGroup[group_id]
      vnic.remove_security_group(group)

      host_had_secg_already = false
      group.host_nodes.each {|host_node|
        tasks = []
        call_packetfilter_service(host_node,"update_isolation_group",group_id,tasks)

        #TODO: Handle referencers and referencees
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
