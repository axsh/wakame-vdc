# -*- coding: utf-8 -*-

module Dcmgr::VNet::NetworkModes

  class SecurityGroup
    include Dcmgr::VNet::Netfilter::Chains
    include Dcmgr::VNet::Netfilter::NetfilterTasks
    include Dcmgr::Helpers::NicHelper

    def init_vnic(vnic_map)
      [
        # chain setup for both layers
        vnic_chains(vnic_map[:uuid]).map {|chain| chain.create},
        forward_chain_jumps(vnic_map[:uuid]),
        nat_prerouting_chain_jumps(vnic_map[:uuid]),
        vnic_main_chain_jumps(vnic_map),
        vnic_main_drop_rules(vnic_map),
        # l2 standard rules
        accept_outbound_arp(vnic_map),
        accept_outbound_ipv4(vnic_map),
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
        translate_metadata_address(vnic_map)
      ].flatten.compact
    end

    def destroy_vnic(vnic_map)
      [
        forward_chain_jumps(vnic_map[:uuid], "del"),
        nat_prerouting_chain_jumps(vnic_map[:uuid], "del"),
        vnic_chains(vnic_map[:uuid]).map {|chain| chain.destroy}
      ].flatten
    end

    def set_vnic_security_groups(vnic_id, secg_ids)
      [
        I.vnic_l2_iso_chain(vnic_id).flush,
        I.vnic_l2_ref_chain(vnic_id).flush,
        I.vnic_l2_secg_chain(vnic_id).flush,
        I.vnic_l3_iso_chain(vnic_id).flush,
        I.vnic_l3_ref_chain(vnic_id).flush,
        I.vnic_l3_secg_chain(vnic_id).flush,
        O.vnic_l3_secg_chain(vnic_id).flush
      ] +
      secg_ids.map { |secg_id|
        [I.vnic_l2_iso_chain(vnic_id).add_jump(I.secg_l2_iso_chain(secg_id)),
        I.vnic_l2_ref_chain(vnic_id).add_jump(I.secg_l2_ref_chain(secg_id)),
        I.vnic_l2_secg_chain(vnic_id).add_jump(I.secg_l2_rules_chain(secg_id)),
        I.vnic_l3_iso_chain(vnic_id).add_jump(I.secg_l3_iso_chain(secg_id)),
        I.vnic_l3_ref_chain(vnic_id).add_jump(I.secg_l3_ref_chain(secg_id)),
        I.vnic_l3_secg_chain(vnic_id).add_jump(I.secg_l3_rules_chain(secg_id)),
        O.vnic_l3_secg_chain(vnic_id).add_jump(O.secg_l3_rules_chain(secg_id))]
      }.flatten
    end
  end

end
