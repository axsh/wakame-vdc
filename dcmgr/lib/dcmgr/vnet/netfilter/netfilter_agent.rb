# -*- coding: utf-8 -*-

module Dcmgr::VNet::Netfilter
  class NetfilterAgent
    include Dcmgr::Logger
    include Dcmgr::VNet::Netfilter::Chains
    include Dcmgr::Helpers::NicHelper
    include Dcmgr::VNet::Netfilter::NetfilterTasks

    attr_accessor :host_caller

    def initialize
      @pending_changes = {}
    end

    def add_changes(host, cmds)
      if @pending_changes.has_key?(host)
        @pending_changes[host] += cmds
        @pending_changes[host].uniq!
      else
        @pending_changes[host] = cmds.uniq
      end
    end

    def init_security_group(host, group)
      group_id = group.canonical_uuid
      logger.info "Telling host '#{host.canonical_uuid}' to initialize security group '#{group_id}'"

      friend_ips = group.vnic_ips

      add_changes(host,
        secg_chains(group_id).map {|chain| chain.create} +
        isog_chains(group_id).map {|chain| chain.create}
      )

      update_secg_rules(host, group)
      update_isolation_group(host, group, friend_ips)

      handle_referencees(host, group)
    end

    def destroy_security_group(host, group_id)
      logger.info "Telling host '#{host.canonical_uuid}' to destroy security group '#{group_id}'"

      add_changes(host,
        secg_chains(group_id).map {|chain| chain.destroy} +
        isog_chains(group_id).map {|chain| chain.destroy}
      )
    end

    def update_isolation_group(host, group, friend_ips = nil)
      group_id = group.canonical_uuid
      logger.info "Telling host '#{host.canonical_uuid}' to update isolation group '#{group_id}'"
      friend_ips ||= group.vnic_ips

      l2c = I.secg_l2_iso_chain(group_id)
      l3c = I.secg_l3_iso_chain(group_id)
      add_changes(host, [
          l2c.flush,
          l3c.flush,
          friend_ips.map { |f_ip|
            [l2c.add_rule(accept_arp_from_ip(f_ip)),
            l3c.add_rule("-s #{f_ip} -j ACCEPT")]
          }
        ].flatten
      )
    end

    def init_vnic_on_host(host, vnic)
      logger.info "Telling host '#{host.canonical_uuid}' to initialize vnic '#{vnic.canonical_uuid}'."
      vnic_map = vnic.to_hash
      return if vnic_map[:network].nil?
      add_changes(host, network_mode(vnic_map).init_vnic(vnic_map))
    end

    def destroy_vnic_on_host(host, vnic)
      logger.info "Telling host '#{host.canonical_uuid}' to destroy vnic '#{vnic.canonical_uuid}'."

      vnic_map = vnic.to_hash
      return if vnic_map[:network].nil?
      add_changes(host, network_mode(vnic_map).destroy_vnic(vnic_map))
    end

    def set_vnic_security_groups(host, vnic, group_ids = nil)
      group_ids ||= vnic.security_groups.map { |sg| sg.canonical_uuid}
      logger.info "Telling host '#{host.canonical_uuid}' to set security groups of vnic '#{vnic.canonical_uuid}' to #{group_ids}."

      vnic_map = vnic.to_hash
      return if vnic_map[:network].nil?
      add_changes(host, network_mode(vnic_map).set_vnic_security_groups(vnic_map[:uuid], group_ids))
    end

    def handle_referencees(host, group, destroyed_vnic = nil)
      #TODO: Right now all of this is updated every time a single referencee is changed
      # It would be better if we could handle it per referencee group somehow
      rules = group.rules_array_only_ref
      translated_ref_rules = group.referencees.map { |reffee|
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

      secg_id = group.canonical_uuid
      l2ref_chain = I.secg_l2_ref_chain(secg_id)
      l3ref_chain = I.secg_l3_ref_chain(secg_id)
      add_changes(host,
        [l2ref_chain.flush, l3ref_chain.flush] +
        ref_ips.map { |r_ip|
          l2ref_chain.add_rule(accept_arp_from_ip(r_ip))
        } +
        parse_rules(translated_ref_rules).map { |r|
          l3ref_chain.add_rule(r)
        }
      )
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

    def update_secg_rules(host, group)
      secg_id = group.canonical_uuid
      rules = group.rules_array_no_ref
      l2chain = I.secg_l2_rules_chain(secg_id)
      l3chain = I.secg_l3_rules_chain(secg_id)

      add_changes(host,
        [I.secg_l2_rules_chain(secg_id).flush, I.secg_l3_rules_chain(secg_id).flush] +
        parse_arp_for_rules(rules).map {|rule| l2chain.add_rule(rule)} +
        parse_rules(rules).map {|rule| l3chain.add_rule(rule)}
      )
    end

    def commit_changes
      @pending_changes.each { |host, cmds|
        host_caller.call(host, cmds)
      }

      @pending_changes = {}
      nil
    end

    private
    def network_mode(vnic_map)
      Dcmgr::VNet::NetworkModes.get_mode(vnic_map[:network][:network_mode])
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
end
