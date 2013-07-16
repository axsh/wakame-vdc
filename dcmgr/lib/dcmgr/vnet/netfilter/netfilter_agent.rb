# -*- coding: utf-8 -*-

module Dcmgr::VNet::Netfilter::NetfilterAgent
  def self.included klass
    klass.class_eval do
      include Dcmgr::Logger
      include Dcmgr::VNet::Netfilter::Chains
      include Dcmgr::Helpers::NicHelper
      include Dcmgr::VNet::Netfilter::NetfilterTasks
    end
  end
  I = Dcmgr::VNet::Netfilter::Chains::Inbound
  O = Dcmgr::VNet::Netfilter::Chains::Outbound

  def init_vnic(vnic_id, vnic_map)
    logger.info "Creating chains for vnic '#{vnic_id}'."
    # This is a bug in Isono where the gw address is actually the host's
    host_ip = Isono::Util.default_gw_ipaddr rescue nil

    exec [
      # chain setup for both layers
      vnic_chains(vnic_id).map {|chain| chain.create},
      forward_chain_jumps(vnic_map[:uuid]),
      nat_prerouting_chain_jumps(vnic_map[:uuid]),
      vnic_main_chain_jumps(vnic_map),
      vnic_main_drop_rules(vnic_map),
      # l2 standard rules
      drop_ip_spoofing(vnic_map),
      drop_mac_spoofing(vnic_map),
      accept_arp_from_gateway(vnic_map),
      accept_arp_from_dns(vnic_map),
      accept_garp_from_gateway(vnic_map),
      accept_arp_reply_with_correct_mac_ip_combo(vnic_map),
      accept_ipv4_protocol(vnic_map),
      # l3 standard rules
      accept_related_established(vnic_map),
      accept_wakame_dns(vnic_map),
      accept_wakame_dhcp_only(vnic_map),
      # address translation rules
      # translate_logging_address(vnic_map, host_ip),
      translate_metadata_address(vnic_map)
    ].flatten.compact
  end

  def destroy_vnic(vnic_id)
    logger.info "Removing chains for vnic '#{vnic_id}'."
    exec forward_chain_jumps(vnic_id, "del")
    exec nat_prerouting_chain_jumps(vnic_id, "del")
    exec vnic_chains(vnic_id).map {|chain| chain.destroy}
  end

  def init_security_group(secg_id, rules)
    logger.info "Adding security chains for group '#{secg_id}'."
    exec secg_chains(secg_id).map {|chain| chain.create }
    update_sg_rules(secg_id, rules)
  end

  def destroy_security_group(secg_id)
    logger.info "Removing security chains for group '#{secg_id}'."
    exec secg_chains(secg_id).map {|chain| chain.destroy }
  end

  def init_isolation_group(isog_id, friend_ips)
    logger.info "Adding isolation chains for group '#{isog_id}'."
    exec isog_chains(isog_id).map {|chain| chain.create}
    update_isolation_group(isog_id, friend_ips)
  end

  def destroy_isolation_group(isog_id)
    logger.info "Removing isolation chains for group '#{isog_id}'."
    exec isog_chains(isog_id).map {|chain| chain.destroy}
  end

  def set_vnic_security_groups(vnic_id, secg_ids)
    logger.info "Setting security groups of vnic '#{vnic_id}' to [#{secg_ids.join(", ")}]."
    exec [
      I.vnic_l2_iso_chain(vnic_id).flush,
      I.vnic_l2_ref_chain(vnic_id).flush,
      I.vnic_l3_iso_chain(vnic_id).flush,
      I.vnic_l3_ref_chain(vnic_id).flush,
      I.vnic_l3_secg_chain(vnic_id).flush,
      O.vnic_l3_secg_chain(vnic_id).flush
    ]

    exec secg_ids.map { |secg_id|
      [I.vnic_l2_iso_chain(vnic_id).add_jump(I.secg_l2_iso_chain(secg_id)),
      I.vnic_l2_ref_chain(vnic_id).add_jump(I.secg_l2_ref_chain(secg_id)),
      I.vnic_l3_iso_chain(vnic_id).add_jump(I.secg_l3_iso_chain(secg_id)),
      I.vnic_l3_ref_chain(vnic_id).add_jump(I.secg_l3_ref_chain(secg_id)),
      I.vnic_l3_secg_chain(vnic_id).add_jump(I.secg_l3_rules_chain(secg_id)),
      O.vnic_l3_secg_chain(vnic_id).add_jump(O.secg_l3_rules_chain(secg_id))]
    }.flatten
  end

  def update_sg_rules(secg_id, rules)
    logger.info "Updating rules for security group: '#{secg_id}'"

    chain = I.secg_l3_rules_chain(secg_id)
    exec(Dcmgr::VNet::Netfilter.parse_rules(rules).map { |rule|
      chain.add_rule rule
    })
  end

  def update_isolation_group(group_id, friend_ips)
    logger.info "Updating vnics in isolation group '#{group_id}'."
    l2c = I.secg_l2_iso_chain(group_id)
    l3c = I.secg_l3_iso_chain(group_id)
    exec [
      l2c.flush,
      l3c.flush,
      friend_ips.map { |f_ip|
        [l2c.add_rule("--protocol arp --arp-opcode Request --arp-ip-src #{f_ip} -j ACCEPT"),
        l3c.add_rule("-s #{f_ip} -j ACCEPT")]
      }
    ].flatten
  end

  def remove_all_chains
    prefix = Dcmgr::VNet::Netfilter::Chains::CHAIN_PREFIX
    logger.info "Removing all chains prefixed by '#{prefix}'."
    # We flush all chains first so there are no links left that would
    # prevent us from deleting them.

    # Delete forward and prerouting jumps
    #TODO: Write this cleaner... probably in ruby instead of bash
    ["iptables"].each { |bin|
      {:filter => :FORWARD, :nat => :PREROUTING}.each { |table,chain|
        system("
          #{bin} -t #{table} -L #{chain} --line-numbers | grep -q vdc_vif-
            while [ \"$?\" == \"0\" ]; do
            #{bin} -t #{table} -D #{chain} $(#{bin} -t #{table} -L #{chain} --line-numbers | grep -m 1 vdc_vif- | cut -d ' ' -f1)
            #{bin} -t #{table} -L #{chain} --line-numbers | grep -q vdc_vif-
          done
        ")
        system("for i in $(iptables -t #{table} -L | grep 'Chain #{prefix}' | cut -d ' ' -f2); do iptables -t #{table} -F $i; done")
        system("for i in $(iptables -t #{table} -L | grep 'Chain #{prefix}' | cut -d ' ' -f2); do iptables -t #{table} -X $i; done")
      }
    }

    # Flush 'em all
    system("for i in $(ebtables -L | grep 'Bridge chain: #{prefix}' | cut -d ' ' -f3 | cut -d ',' -f1); do ebtables -F; done")

    # Kill 'em all
    system("for i in $(ebtables -L | grep 'Bridge chain: #{prefix}' | cut -d ' ' -f3 | cut -d ',' -f1); do ebtables -X; done")
  end

  private
  def exec(cmds)
    #TODO: Make vebose commands options
    cmds = [cmds] unless cmds.is_a?(Array)
    puts cmds.join("\n")
    system cmds.join("\n")
  end
end
