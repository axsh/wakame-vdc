# -*- coding: utf-8 -*-
require "ipaddress"

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
    return if vnic_map[:network].nil?
    exec network_mode(vnic_map).init_vnic(vnic_map)
  end

  def destroy_vnic(vnic_map)
    logger.info "Removing chains for vnic '#{vnic_map[:uuid]}'."
    return if vnic_map[:network].nil?
    exec network_mode(vnic_map).destroy_vnic(vnic_map)
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

  def set_vnic_security_groups(vnic_map, secg_ids)
    logger.info "Setting security groups of vnic '#{vnic_map[:uuid]}' to [#{secg_ids.join(", ")}]."
    exec network_mode(vnic_map).set_vnic_security_groups(vnic_map[:uuid], secg_ids)
  end

  def set_sg_referencees(secg_id, ref_ips, rules)
    logger.info "Setting referencees for #{secg_id} to [#{ref_ips.join(", ")}]"
    l2ref_chain = I.secg_l2_ref_chain(secg_id)
    l3ref_chain = I.secg_l3_ref_chain(secg_id)
    exec(
      [l2ref_chain.flush, l3ref_chain.flush] +
      ref_ips.map { |r_ip|
        l2ref_chain.add_rule("--protocol arp --arp-opcode Request --arp-ip-src #{r_ip} -j ACCEPT")
      } +
      parse_rules(rules).map { |r|
        l3ref_chain.add_rule(r)
      }
    )
  end

  def update_sg_rules(secg_id, rules)
    logger.info "Updating rules for security group: '#{secg_id}'"

    l2chain = I.secg_l2_rules_chain(secg_id)
    l3chain = I.secg_l3_rules_chain(secg_id)

    exec(
      [I.secg_l2_rules_chain(secg_id).flush, I.secg_l3_rules_chain(secg_id).flush] +
      parse_arp_for_rules(rules).map {|rule| l2chain.add_rule(rule)} +
      parse_rules(rules).map {|rule| l3chain.add_rule(rule)}
    )
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

  def network_mode(vnic_map)
    Dcmgr::VNet::NetworkModes.get_mode(vnic_map[:network][:network_mode])
  end

  def accept_arp_from_ip(ipv4)
    "--protocol arp --arp-opcode Request --arp-ip-src #{ipv4} -j ACCEPT"
  end

  def parse_arp_for_rules(sg_rules)
    sg_rules.map { |rule| accept_arp_from_ip(rule[:ip_source]) }.uniq
  end

  def parse_rules(sg_rules)
    sg_rules.map { |rule|
      case rule[:ip_protocol]
      when 'tcp', 'udp'
        if rule[:ip_fport] == rule[:ip_tport]
          "-p #{rule[:ip_protocol]} -s #{rule[:ip_source]} --dport #{rule[:ip_fport]} -j ACCEPT"
        else
          "-p #{rule[:ip_protocol]} -s #{rule[:ip_source]} --dport #{rule[:ip_fport]}:#{rule[:ip_tport]} -j ACCEPT"
        end
      when 'icmp'
        # icmp
        #   This extension can be used if `--protocol icmp' is specified. It provides the following option:
        #   [!] --icmp-type {type[/code]|typename}
        #     This allows specification of the ICMP type, which can be a numeric ICMP type, type/code pair, or one of the ICMP type names shown by the command
        #      iptables -p icmp -h
        if rule[:icmp_type] == -1 && rule[:icmp_code] == -1
          "-p icmp -s #{rule[:ip_source]} -j ACCEPT"
        else
          "-p icmp -s #{rule[:ip_source]} --icmp-type #{rule[:icmp_type]}/#{rule[:icmp_code]} -j ACCEPT"
        end
      end
    }
  end
end
