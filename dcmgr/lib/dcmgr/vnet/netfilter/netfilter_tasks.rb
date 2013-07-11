# -*- coding: utf-8 -*-

module Dcmgr::VNet::Netfilter::NetfilterTasks
  def self.included klass
    klass.class_eval do
      include Dcmgr::VNet::Netfilter::Chains
    end
  end
  I = Dcmgr::VNet::Netfilter::Chains::Inbound
  O = Dcmgr::VNet::Netfilter::Chains::Outbound

  private
  def accept_arp_from_gateway(vnic_map)
    vnic_map[:network] && vnic_map[:network][:ipv4_gw] && I.vnic_l2_stnd_chain(vnic_map[:uuid]).add_rule("--protocol arp --arp-opcode Request --arp-ip-src=#{vnic_map[:network][:ipv4_gw]} --arp-ip-dst=#{vnic_map[:address]} -j ACCEPT")
  end

  def accept_arp_from_dns(vnic_map)
    vnic_map[:network] && vnic_map[:network][:dns_server] && I.vnic_l2_stnd_chain(vnic_map[:uuid]).add_rule("--protocol arp --arp-opcode Request --arp-ip-src=#{vnic_map[:network][:dns_server]} --arp-ip-dst=#{vnic_map[:address]} -j ACCEPT")
  end

  def accept_garp_from_gateway(vnic_map)
    vnic_map[:network] && vnic_map[:network][:ipv4_gw] && I.vnic_l2_stnd_chain(vnic_map[:uuid]).add_rule("--protocol arp --arp-gratuitous --arp-ip-src=#{vnic_map[:network][:ipv4_gw]} -j ACCEPT")
  end

  def accept_arp_reply_with_correct_mac_ip_combo(vnic_map)
    I.vnic_l2_stnd_chain(vnic_map[:uuid]).add_rule("--protocol arp --arp-opcode Reply --arp-ip-dst=#{vnic_map[:address]} --arp-mac-dst=#{clean_mac(vnic_map[:mac_addr])} -j ACCEPT")
  end

  def drop_ip_spoofing(vnic_map)
    # drop ip spoofing
    O.vnic_l2_stnd_chain(vnic_map[:uuid]).add_rule("--protocol arp --arp-ip-src ! #{vnic_map[:address]} -j DROP")
    #TODO: drop ip spoofing to the host EbtablesRule.new(:filter,:input,:arp,:outgoing,"--protocol arp --arp-ip-src ! #{self.ip} #{EbtablesRule.log_arp(self.log_prefix) if self.enable_logging} -j DROP")
    #TODO: drop ip spoofing from the host EbtablesRule.new(:filter,:output,:arp,:incoming,"--protocol arp --arp-ip-dst ! #{self.ip} #{EbtablesRule.log_arp(self.log_prefix) if self.enable_logging} -j DROP")
  end

  def drop_mac_spoofing(vnic_map)
    # drop mac spoofing
    O.vnic_l2_stnd_chain(vnic_map[:uuid]).add_rule("--protocol arp --arp-mac-src ! #{clean_mac(vnic_map[:mac_addr])} -j DROP")
    #TODO: drop mac spoofing to the host EbtablesRule.new(:filter,:input,:arp,:outgoing,"--protocol arp --arp-mac-src ! #{self.mac} #{EbtablesRule.log_arp(self.log_prefix) if self.enable_logging} -j DROP")
    #TODO: drop mac spoofing from the host EbtablesRule.new(:filter,:output,:arp,:incoming,"--protocol arp --arp-mac-dst ! #{self.mac} #{EbtablesRule.log_arp(self.log_prefix) if self.enable_logging} -j DROP")
  end

  # accept all ip traffic on the data link layer (l2)
  # ip filtering is done on the network layer (l3)
  def accept_ipv4_protocol(vnic_map)
    I.vnic_l2_stnd_chain(vnic_map[:uuid]).add_rule("--protocol IPv4 -j ACCEPT")
  end

  #TODO: Read up on what iptables means by related/established for connectionless protocols like icmp and umd. Then comment about that here.
  def accept_related_established(vnic_map)
    I.vnic_l3_stnd_chain(vnic_map[:uuid]).add_rule("-m state --state RELATED,ESTABLISHED -j ACCEPT")
  end

  # accept only wakame's dns (users can use their custom ones by opening a port in their security groups)
  def accept_wakame_dns(vnic_map)
    I.vnic_l3_stnd_chain(vnic_map[:uuid]).add_rule("-p udp -d #{vnic_map[:network][:dns_server]} --dport 53 -j ACCEPT") if vnic_map[:network] && vnic_map[:network][:dns_server]
  end

  # Explicitely block out dhcp that isn't wakame's.
  # Unlike dns, you can not allow more than one dhcp server in a network.
  def accept_wakame_dhcp_only(vnic_map)
    [vnic_map[:network] && vnic_map[:network][:dhcp_server] && I.vnic_l3_stnd_chain(vnic_map[:uuid]).add_rule("-p udp ! -s #{vnic_map[:network][:dhcp_server]} --sport 67:68 -j DROP"),
    vnic_map[:network] && vnic_map[:network][:dhcp_server] && I.vnic_l3_stnd_chain(vnic_map[:uuid]).add_rule("-p udp -s #{vnic_map[:network][:dhcp_server]} --sport 67:68 -j ACCEPT")]
  end

  def forward_chain_jumps(vnic_id, action = "add")
    [
      l2_forward_chain.send("#{action}_rule", "-o #{vnic_id} -j #{I.vnic_l2_main_chain(vnic_id).name}"),
      l2_forward_chain.send("#{action}_rule", "-i #{vnic_id} -j #{O.vnic_l2_main_chain(vnic_id).name}"),
      l3_forward_chain.send("#{action}_rule", "-m physdev --physdev-is-bridged --physdev-out #{vnic_id} -j #{I.vnic_l3_main_chain(vnic_id).name}"),
      l3_forward_chain.send("#{action}_rule", "-m physdev --physdev-is-bridged --physdev-in #{vnic_id} -j #{O.vnic_l3_main_chain(vnic_id).name}")
    ]
  end

  def vnic_main_chain_jumps(vnic_map)
    # Add main l2 jumps
    vnic_id = vnic_map[:uuid]
    l2_main = I.vnic_l2_main_chain(vnic_id)
    l3_main = I.vnic_l3_main_chain(vnic_id)

    [vnic_l2_inbound_chains(vnic_id).map {|chain|
      next if chain == l2_main
      l2_main.add_jump(chain)
    }.compact,

    # Add main l3 jumps
    vnic_l3_inbound_chains(vnic_id).map {|chain|
      next if chain == l3_main
      l3_main.add_jump(chain)
    }.compact,

    O.vnic_l2_main_chain(vnic_id).add_jump(O.vnic_l2_stnd_chain(vnic_id))]
  end

  def vnic_main_drop_rules(vnic_map)
    [I.vnic_l2_main_chain(vnic_map[:uuid]).add_rule("-j DROP"),
    I.vnic_l3_main_chain(vnic_map[:uuid]).add_rule("-j DROP")]
  end
end
