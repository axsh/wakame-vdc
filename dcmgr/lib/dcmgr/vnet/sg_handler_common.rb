# -*- coding: utf-8 -*-

module Dcmgr::VNet::SGHandlerCommon
  def self.included klass
    klass.class_eval do
      include Dcmgr::Logger
    end
  end

  def call_packetfilter_service(host_node, method, *args)
    raise NotImplementedError,  "Classes that include the sg handler module must define a 'call_packetfilter_service(host_node, method, *args)' method"
  end

  private
  def init_security_group(host, group)
    group_id = group.canonical_uuid
    logger.info "Telling host '#{host.canonical_uuid}' to initialize security group '#{group_id}'"
    call_packetfilter_service(host, "init_security_group", group_id, group.rules_array_no_ref)

    friend_ips = group.vnic_ips
    call_packetfilter_service(host, "init_isolation_group", group_id, friend_ips)

    handle_referencees(host, group)
  end

  def destroy_security_group(host, group_id)
    logger.info "Telling host '#{host.canonical_uuid}' to destroy security group '#{group_id}'"
    call_packetfilter_service(host, "destroy_security_group", group_id)
    call_packetfilter_service(host, "destroy_isolation_group", group_id)
  end

  def update_isolation_group(host, group, friend_ips = nil)
    group_id = group.canonical_uuid
    logger.info "Telling host '#{host.canonical_uuid}' to update isolation group '#{group_id}'"
    call_packetfilter_service(host, "update_isolation_group", group_id, friend_ips || group.vnic_ips)
  end

  def init_vnic_on_host(host, vnic)
    logger.info "Telling host '#{host.canonical_uuid}' to initialize vnic '#{vnic.canonical_uuid}'."
    call_packetfilter_service(host, "init_vnic", vnic.canonical_uuid, vnic.to_hash)
  end

  def destroy_vnic_on_host(host_node, vnic)
    logger.info "Telling host '#{host_node.canonical_uuid}' to destroy vnic '#{vnic.canonical_uuid}'."
    call_packetfilter_service(host_node, "destroy_vnic", vnic.to_hash)
  end

  def set_vnic_security_groups(host, vnic, group_ids = nil)
    group_ids ||= vnic.security_groups.map { |sg| sg.canonical_uuid}
    logger.info "Telling host '#{host.canonical_uuid}' to set security groups of vnic '#{vnic.canonical_uuid}' to #{group_ids}."
    call_packetfilter_service(host, "set_vnic_security_groups", vnic.to_hash, group_ids)
  end

  def handle_referencees(host, group, destroyed_vnic = nil)
    #TODO: Right now all of this is updated every time a single referencee is changed
    # It would be better if we could handle it per referencee group somehow
    rules = group.rules_array_only_ref
    parsed_rules = group.referencees.map { |reffee|
      rules.map { |r|
        if r[:ip_source] == reffee.canonical_uuid
          reffee_ips = reffee.vnic_ips
          reffee_ips -= destroyed_vnic.direct_ip_lease.map {|ip| ip.ipv4_s} if destroyed_vnic
          reffee_ips.map { |ref_ip|
            parsed_rule = r.dup
            parsed_rule[:ip_source] = ref_ip
            parsed_rule
          }
        end
      }
    }.flatten.compact

    ref_ips = group.referencees.map { |ref| ref.vnic_ips}.flatten.uniq
    ref_ips -= destroyed_vnic.direct_ip_lease.map {|ip| ip.ipv4_s} if destroyed_vnic

    call_packetfilter_service(host, "set_sg_referencees", group.canonical_uuid, ref_ips, parsed_rules)
  end

  def refresh_referencers(group, destroyed_vnic = nil)
    referencers ||= group.referencers
    referencers.each { |ref_g|
      ref_g.online_host_nodes.each { |ref_h|
        logger.info "Telling host '#{ref_h.canonical_uuid}' to update referencees for group '#{ref_g.canonical_uuid}'."
        handle_referencees(ref_h, ref_g, destroyed_vnic)
      }
    }
  end

end
