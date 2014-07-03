# -*- coding: utf-8 -*-

module Dcmgr::EdgeNetworking::Netfilter::NetfilterTasks
  def self.included klass
    klass.class_eval do
      include Dcmgr::EdgeNetworking::Netfilter::Chains
    end
  end
  I = Dcmgr::EdgeNetworking::Netfilter::Chains::Inbound
  O = Dcmgr::EdgeNetworking::Netfilter::Chains::Outbound

  private
  def accept_arp_from_gateway(vnic_map)
    vnic_map[:network] && vnic_map[:network][:ipv4_gw] &&
      I.vnic_l2_stnd_chain(vnic_map[:uuid]).add_rule(
        accept_arp_from_ip(vnic_map[:network][:ipv4_gw], vnic_map[:address])
      )
  end

  def accept_arp_from_dns(vnic_map)
    vnic_map[:network] && vnic_map[:network][:dns_server] &&
      I.vnic_l2_stnd_chain(vnic_map[:uuid]).add_rule(
        accept_arp_from_ip(vnic_map[:network][:dns_server], vnic_map[:address])
      )
  end

  def accept_garp_from_gateway(vnic_map)
    vnic_map[:network] && vnic_map[:network][:ipv4_gw] &&
      I.vnic_l2_stnd_chain(vnic_map[:uuid]).add_rule(
        "--protocol arp --arp-gratuitous --arp-ip-src=#{vnic_map[:network][:ipv4_gw]} -j ACCEPT"
      )
  end

  def accept_arp_reply_with_correct_mac_ip_combo(vnic_map)
    I.vnic_l2_stnd_chain(vnic_map[:uuid]).add_rule(
      "--protocol arp --arp-opcode Reply --arp-ip-dst=#{vnic_map[:address]} --arp-mac-dst=#{clean_mac(vnic_map[:mac_addr])} -j ACCEPT"
    )
  end

  def accept_outbound_arp(vnic_map)
    O.vnic_l2_stnd_chain(vnic_map[:uuid]).add_rule(
      "--protocol arp --arp-ip-src #{vnic_map[:address]} --arp-mac-src #{clean_mac(vnic_map[:mac_addr])} -j ACCEPT"
    )
  end

  def accept_outbound_ipv4(vnic_map)
    O.vnic_l2_stnd_chain(vnic_map[:uuid]).add_rule(
      "--protocol IPv4 --among-src #{clean_mac(vnic_map[:mac_addr])}=#{vnic_map[:address]} -j ACCEPT"
    )
  end

  # accept all ip traffic on the data link layer (l2)
  # ip filtering is done on the network layer (l3)
  def accept_ipv4_protocol(vnic_map)
    I.vnic_l2_stnd_chain(vnic_map[:uuid]).add_rule("--protocol IPv4 -j ACCEPT")
  end

  #TODO: Read up on what iptables means by related/established for connectionless protocols like icmp and umd. Then comment about that here.
  def accept_related_established(vnic_map)
    I.vnic_l3_stnd_chain(vnic_map[:uuid]).add_rule(
      "-m state --state RELATED,ESTABLISHED -j ACCEPT"
    )
  end

  # accept only wakame's dns (users can use their custom ones by opening a port in their security groups)
  def accept_wakame_dns(vnic_map)
    I.vnic_l3_stnd_chain(vnic_map[:uuid]).add_rule(
      "-p udp -d #{vnic_map[:network][:dns_server]} --dport 53 -j ACCEPT"
    ) if vnic_map[:network] && vnic_map[:network][:dns_server]
  end

  # Explicitely block out dhcp that isn't wakame's.
  # Unlike dns, you can not allow more than one dhcp server in a network.
  def accept_wakame_dhcp_only(vnic_map)
    [
      vnic_map[:network] && vnic_map[:network][:dhcp_server] &&
      I.vnic_l3_stnd_chain(vnic_map[:uuid]).add_rule(
        "-p udp ! -s #{vnic_map[:network][:dhcp_server]} --sport 67:68 -j DROP"
      ),
      vnic_map[:network] && vnic_map[:network][:dhcp_server] &&
      I.vnic_l3_stnd_chain(vnic_map[:uuid]).add_rule(
        "-p udp -s #{vnic_map[:network][:dhcp_server]} --sport 67:68 -j ACCEPT"
      )
    ]
  end

  def translate_metadata_address(vnic_map)
    return nil unless vnic_map[:network] && vnic_map[:network][:metadata_server] && vnic_map[:network][:metadata_server_port]
    [
      O.vnic_l3_dnat_chain(vnic_map[:uuid]).add_rule(
        "-d 169.254.169.254 -p tcp --dport 80 -j DNAT --to-destination #{vnic_map[:network][:metadata_server]}:#{vnic_map[:network][:metadata_server_port]}"
      ),
      I.vnic_l2_stnd_chain(vnic_map[:uuid]).add_rule(
        accept_arp_from_ip(vnic_map[:network][:metadata_server], vnic_map[:address])
      ),
      I.vnic_l3_stnd_chain(vnic_map[:uuid]).add_rule(
        "-p tcp -s #{vnic_map[:network][:metadata_server]} --sport #{vnic_map[:network][:metadata_server_port]} -j ACCEPT"
      )
    ]
  end

  def translate_logging_address(vnic_map)
    enabled = Dcmgr.conf.use_logging_service
    log_ip = Dcmgr.conf.logging_service_ip
    log_port = Dcmgr.conf.logging_service_port
    return nil unless enabled && log_ip && log_port

    #TODO: Figure out host ip
    [:udp, :tcp].each { |prot|
      O.vnic_l3_dnat_chain(vnic_map[:uuid]).add_rule(
        "-d #{log_ip} -p #{prot} --dport #{log_port} -j DNAT --to-destination #{host_ip}:#{log_port}"
      )
    }
  end

  def forward_chain_jumps(vnic_id, action = "add")
    [
      l2_forward_chain.send("#{action}_rule", "-o #{vnic_id} -j #{I.vnic_l2_main_chain(vnic_id).name}"),
      l2_forward_chain.send("#{action}_rule", "-i #{vnic_id} -j #{O.vnic_l2_main_chain(vnic_id).name}"),
      l3_forward_chain.send("#{action}_rule", "-m physdev --physdev-is-bridged --physdev-out #{vnic_id} -j #{I.vnic_l3_main_chain(vnic_id).name}"),
      l3_forward_chain.send("#{action}_rule", "-m physdev --physdev-is-bridged --physdev-in #{vnic_id} -j #{O.vnic_l3_main_chain(vnic_id).name}")
    ]
  end

  def nat_prerouting_chain_jumps(vnic_id, action = "add")
    [
      l3_nat_prerouting_chain.send("#{action}_rule", "-m physdev --physdev-in #{vnic_id} -j #{O.vnic_l3_dnat_chain(vnic_id).name}")
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

    O.vnic_l2_main_chain(vnic_id).add_jump(O.vnic_l2_stnd_chain(vnic_id)),
    O.vnic_l3_main_chain(vnic_id).add_jump(O.vnic_l3_secg_chain(vnic_id))]
  end

  def vnic_main_drop_rules(vnic_map)
    [
      I.vnic_l2_main_chain(vnic_map[:uuid]).add_rule("-j DROP"),
      I.vnic_l3_main_chain(vnic_map[:uuid]).add_rule("-j DROP"),
      O.vnic_l2_main_chain(vnic_map[:uuid]).add_rule("-j DROP")
    ]
  end

  # Helper method for accepting ARP from an ip
  def accept_arp_from_ip(from, to = nil)
    "--protocol arp --arp-opcode Request --arp-ip-src=#{from} #{to.nil? ? "" : "--arp-ip-dst=#{to}"} -j ACCEPT"
  end
end
