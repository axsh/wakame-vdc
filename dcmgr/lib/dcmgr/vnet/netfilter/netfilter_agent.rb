# -*- coding: utf-8 -*-

module Dcmgr::VNet::Netfilter::NetfilterAgent
  def self.included klass
    klass.class_eval do
      include Dcmgr::VNet::Netfilter::Chains
      include Dcmgr::Helpers::NicHelper
    end
  end

  def init_vnic(vnic_id, vnic_map)
    logger.info "Adding chains for vnic '#{vnic_id}'."
    exec vnic_chains(vnic_id).map {|chain| chain.create}

    # Add main l2 jumps
    l2_main = vnic_l2_main_chain(vnic_id)
    exec vnic_l2_chains(vnic_id).map {|chain|
      next if chain == l2_main
      l2_main.add_jump(chain)
    }.compact + [
      "ebtables -A FORWARD -o #{vnic_id} -j #{l2_main.name}",
      l2_main.add_rule("-j DROP")
    ]

    # Add main l3 jumps
    l3_main = vnic_l3_main_chain(vnic_id)
    exec vnic_l3_chains(vnic_id).map {|chain|
      next if chain == l3_main
      l3_main.add_jump(chain)
    }.compact
    exec "iptables -A FORWARD -m physdev --physdev-is-bridged --physdev-out #{vnic_id} -j #{l3_main.name}"
    exec l3_main.add_rule("-j DROP")

    # Add standard rules
    l2std = vnic_l2_stnd_chain(vnic_id)
    exec [
      # accept arp from gateway
      vnic_map[:network] && vnic_map[:network][:ipv4_gw] && l2std.add_rule("--protocol arp --arp-opcode Request --arp-ip-src=#{vnic_map[:network][:ipv4_gw]} --arp-ip-dst=#{vnic_map[:address]} -j ACCEPT"),
      # accept arp from dns
      vnic_map[:network] && vnic_map[:network][:dns_server] && l2std.add_rule("--protocol arp --arp-opcode Request --arp-ip-src=#{vnic_map[:network][:dns_server]} --arp-ip-dst=#{vnic_map[:address]} -j ACCEPT"),
      # drop ip spoofing
      #TODO: Drop spoofing outging # l2std.add_rule("--protocol arp --arp-ip-src ! #{vnic_map[:address]} -j DROP"),
      #TODO: drop ip spoofing to the host EbtablesRule.new(:filter,:input,:arp,:outgoing,"--protocol arp --arp-ip-src ! #{self.ip} #{EbtablesRule.log_arp(self.log_prefix) if self.enable_logging} -j DROP")
      #TODO: drop ip spoofing from the host EbtablesRule.new(:filter,:output,:arp,:incoming,"--protocol arp --arp-ip-dst ! #{self.ip} #{EbtablesRule.log_arp(self.log_prefix) if self.enable_logging} -j DROP")

      # drop mac spoofing
      #TODO: Drop spoofing outgoing l2std.add_rule("--protocol arp --arp-mac-src ! #{clean_mac(vnic_map[:mac_addr])} -j DROP"),
      #TODO: drop mac spoofing to the host EbtablesRule.new(:filter,:input,:arp,:outgoing,"--protocol arp --arp-mac-src ! #{self.mac} #{EbtablesRule.log_arp(self.log_prefix) if self.enable_logging} -j DROP")
      #TODO: drop mac spoofing from the host EbtablesRule.new(:filter,:output,:arp,:incoming,"--protocol arp --arp-mac-dst ! #{self.mac} #{EbtablesRule.log_arp(self.log_prefix) if self.enable_logging} -j DROP")

      # accept garp from gateway
      vnic_map[:network] && vnic_map[:network][:ipv4_gw] && l2std.add_rule("--protocol arp --arp-gratuitous --arp-ip-src=#{vnic_map[:network][:ipv4_gw]} -j ACCEPT"),

      # accept arp replies with the correct mac-ip combo
      l2std.add_rule("--protocol arp --arp-opcode Reply --arp-ip-dst=#{vnic_map[:address]} --arp-mac-dst=#{clean_mac(vnic_map[:mac_addr])} -j ACCEPT"),

      # accept all ip traffic on the data link layer (l2)
      # ip filtering is done on the network layer (l3)
      l2std.add_rule("--protocol IPv4 -j ACCEPT")
    ].compact
    #TODO: Metadata server DNAT
    l3std = vnic_l3_stnd_chain(vnic_id)
    exec [
      # accept related and established connections for all protocols
      #TODO: Read up on what netfilter means by related/established for connectionless protocols like icmp and umd. Then comment about that here.
      # l3std.add_rule("-m state --state RELATED,ESTABLISHED -p tcp -j ACCEPT"),
      # l3std.add_rule("-m state --state RELATED,ESTABLISHED -p udp -j ACCEPT"),
      # l3std.add_rule("-m state --state RELATED,ESTABLISHED -p icmp -j ACCEPT"),
      l3std.add_rule("-m state --state RELATED,ESTABLISHED -j ACCEPT"),

      # accept only wakame's dns (users can use their custom ones by opening a port in their security groups)
      #TODO: Add outgoing rule for this as well IptablesRule.new(:filter,:forward,:udp,:incoming,"-p udp -d #{self.dns_server_ip} --dport #{self.dns_server_port} -j ACCEPT")
      vnic_map[:network] && vnic_map[:network][:dns_server] && l3std.add_rule("-p udp -d #{vnic_map[:network][:dns_server]} --dport 53 -j ACCEPT"),

      # accept only wakame's dhcp.
      vnic_map[:network] && vnic_map[:network][:dhcp_server] && l3std.add_rule("-p udp ! -s #{vnic_map[:network][:dhcp_server]} --sport 67:68 -j DROP"),
      vnic_map[:network] && vnic_map[:network][:dhcp_server] && l3std.add_rule("-p udp -s #{vnic_map[:network][:dhcp_server]} --sport 67:68 -j ACCEPT")
    ].compact
  end

  def destroy_vnic(vnic_id)
    logger.info "Removing chains for vnic '#{vnic_id}'."
    exec vnic_chains(vnic_id).map {|chain| chain.destroy}
  end

  def init_security_group(secg_id, tasks)
    logger.info "Adding security chains for group '#{secg_id}'."
    exec secg_chains(secg_id).map {|chain| chain.create }
    #TODO: Add secg rules to this chain
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

  # Split this in security group and isolation group?
  def set_vnic_security_groups(vnic_id, secg_ids)
    logger.info "Setting security groups of vnic '#{vnic_id}' to [#{secg_ids.join(", ")}]."
    exec [
      vnic_l2_iso_chain(vnic_id).flush,
      vnic_l2_ref_chain(vnic_id).flush,
      vnic_l3_iso_chain(vnic_id).flush,
      vnic_l3_ref_chain(vnic_id).flush,
      vnic_l3_secg_chain(vnic_id).flush
    ]

    exec secg_ids.map { |secg_id|
      [vnic_l2_iso_chain(vnic_id).add_jump(secg_l2_iso_chain(secg_id)),
      vnic_l2_ref_chain(vnic_id).add_jump(secg_l2_ref_chain(secg_id)),
      vnic_l3_iso_chain(vnic_id).add_jump(secg_l3_iso_chain(secg_id)),
      vnic_l3_ref_chain(vnic_id).add_jump(secg_l3_ref_chain(secg_id)),
      vnic_l3_secg_chain(vnic_id).add_jump(secg_l3_rules_chain(secg_id))]
    }.flatten
  end

  def update_sg_rules(secg_id, tasks)
  end

  def update_isolation_group(group_id, friend_ips)
    logger.info "Updating vnics in isolation group '#{group_id}'."
    l2c = secg_l2_iso_chain(group_id)
    l3c = secg_l3_iso_chain(group_id)
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

    # Flush 'em all
    system("for i in $(ebtables -L | grep 'Bridge chain: #{prefix}' | cut -d ' ' -f3 | cut -d ',' -f1); do ebtables -F; done")
    system("for i in $(iptables -L | grep 'Chain #{prefix}' | cut -d ' ' -f2); do iptables -F $i; done")

    # Kill 'em all
    system("for i in $(ebtables -L | grep 'Bridge chain: #{prefix}' | cut -d ' ' -f3 | cut -d ',' -f1); do ebtables -X; done")
    system("for i in $(iptables -L | grep 'Chain #{prefix}' | cut -d ' ' -f2); do iptables -X $i; done")
  end

  private
  def exec(cmds)
    #TODO: Make vebose commands options
    cmds = [cmds] unless cmds.is_a?(Array)
    puts cmds.join("\n")
    system cmds.join("\n")
  end
end
