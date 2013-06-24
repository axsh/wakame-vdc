# -*- coding: utf-8 -*-
module Dcmgr::VNet::Netfilter::NetfilterAgent
  CHAIN_PREFIX="vdc".freeze

  def init_vnic(vnic_id, tasks)
    create_chains(vnic_chains(vnic_id))
  end

  def destroy_vnic(vnic_id)
    remove_chains(vnic_chains(vnic_id))
  end

  def init_security_group(secg_id, tasks)
    create_chains(secg_chains(secg_id))
    #TODO: Add secg rules to this chain
  end

  def destroy_security_group(secg_id)
    remove_chains(secg_chains(secg_id))
  end

  def init_isolation_group(isog_id, tasks)
    create_chains(isog_chains(isog_id))
    #TODO: Add isolation rules for all vnics in the isog (secg in reality) to this chain
  end

  def destroy_isolation_group(isog_id)
    remove_chains(isog_chains(isog_id))
  end

  def set_vnic_security_groups(vnic_id,secg_ids)
    # Clear vdc_vif-yw8f6x94_secg
  end

  def update_sg_rules(secg_id,tasks)
  end

  def update_isolation_group(group_id,tasks)
  end

  def remove_all_chains
    logger.info "Removing all chains prefixed by '#{CHAIN_PREFIX}'."
    #TODO: USE the remove_chains method for this
    system("for i in $(ebtables -L | grep 'Bridge chain: #{CHAIN_PREFIX}' | cut -d ' ' -f3 | cut -d ',' -f1); do ebtables -X $i; done")
    system("for i in $(iptables -L | grep 'Chain #{CHAIN_PREFIX}' | cut -d ' ' -f2); do iptables -F $i; iptables -X $i; done")
  end

  private
  def remove_chains(chains)
    cmds = []
    cmds += chains[:l2].map {|c| "ebtables -F #{c}; ebtables -X #{c}" } if chains[:l2]
    cmds += chains[:l3].map{|c| "iptables -F #{c}; iptables -X #{c}" } if chains[:l3]
    exec cmds
  end

  def create_chains(chains)
    cmds = []
    cmds += chains[:l2].map {|c| "ebtables -N #{c}; ebtables -P #{c} RETURN" } if chains[:l2]
    cmds += chains[:l3].map {|c| "iptables -N #{c}" } if chains[:l3]
    exec cmds
  end

  def exec(cmds)
    #TODO: Make vebose commands options
    puts cmds.join("\n")
    system cmds.join("\n")
  end

  def secg_chains(sg_id)
    { :l3 => ["#{CHAIN_PREFIX}_#{sg_id}_security"]}
  end

  def isog_chains(ig_id)
    { :l2 => ["#{CHAIN_PREFIX}_#{ig_id}_isolation"],
      :l3 => ["#{CHAIN_PREFIX}_#{ig_id}_isolation"]
    }
  end

  def vnic_chains(vnic_id)
    # L2 has the refencers chains and L3 has the referencees chains.
    # Let's say there's secg A that references secg B in one of its rules.
    # The rules are only L3 so secg A needs the referencees chain to add the rules itself.
    # Secg A needs the referencers chain so it can accept ARP packets from vnics in secg B.
    #
    # Basically secg A is referencing secg B so vnics in secg A are referencers and vnics
    # in secg B are referencees. a referencee needs to know about its referencer and a
    # referencer needs to know about its referencee.
  {
    :l2 => [
      "#{CHAIN_PREFIX}_#{vnic_id}_d",
      "#{CHAIN_PREFIX}_#{vnic_id}_d_standard",
      "#{CHAIN_PREFIX}_#{vnic_id}_d_isolation",
      "#{CHAIN_PREFIX}_#{vnic_id}_d_referencers",
    ],
    :l3 => [
      "#{CHAIN_PREFIX}_#{vnic_id}_d",
      "#{CHAIN_PREFIX}_#{vnic_id}_d_standard",
      "#{CHAIN_PREFIX}_#{vnic_id}_d_isolation",
      "#{CHAIN_PREFIX}_#{vnic_id}_d_referencees",
      "#{CHAIN_PREFIX}_#{vnic_id}_d_security" # Only L3 needs the secg chain. We don't have user defined L2 rules atm.
    ]
  }
    end
end
