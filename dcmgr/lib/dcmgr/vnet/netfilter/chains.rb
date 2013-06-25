# -*- coding: utf-8 -*-

module Dcmgr::VNet::Netfilter::Chains
  CHAIN_PREFIX="vdc".freeze

  def secg_l3_rules_chain(sg_id)
    "#{CHAIN_PREFIX}_#{sg_id}_rules"
  end

  def secg_l2_iso_chain(sg_id)
    "#{CHAIN_PREFIX}_#{sg_id}_isolation"
  end

  def secg_l3_iso_chain(sg_id)
    "#{CHAIN_PREFIX}_#{sg_id}_isolation"
  end

  def vnic_l2_main_chain(vnic_id)
    "#{CHAIN_PREFIX}_#{vnic_id}_d"
  end

  def vnic_l2_iso_chain(vnic_id)
    "#{CHAIN_PREFIX}_#{vnic_id}_d_isolation"
  end

  def vnic_l2_stnd_chain(vnic_id)
    "#{CHAIN_PREFIX}_#{vnic_id}_d_standard"
  end

  def vnic_l2_ref_chain(vnic_id)
    "#{CHAIN_PREFIX}_#{vnic_id}_d_reffers"
  end

  def vnic_l3_main_chain(vnic_id)
    "#{CHAIN_PREFIX}_#{vnic_id}_d"
  end

  def vnic_l3_stnd_chain(vnic_id)
    "#{CHAIN_PREFIX}_#{vnic_id}_d_standard"
  end

  def vnic_l3_iso_chain(vnic_id)
    "#{CHAIN_PREFIX}_#{vnic_id}_d_isolation"
  end

  def vnic_l3_ref_chain(vnic_id)
    "#{CHAIN_PREFIX}_#{vnic_id}_d_reffees" # Referencees was too long of a name for iptables (must be under 29 chars)
  end

  def vnic_l3_secg_chain(vnic_id)
    "#{CHAIN_PREFIX}_#{vnic_id}_d_security" # Only L3 needs the secg chain. We don't have user defined L2 rules atm.
  end

  def secg_chains(sg_id)
    {:l3 => [secg_l3_rules_chain(sg_id)]}
  end

  def isog_chains(ig_id)
    { :l2 => [secg_l2_iso_chain(ig_id)],
      :l3 => [secg_l3_iso_chain(ig_id)]
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
        vnic_l2_main_chain(vnic_id),
        vnic_l2_stnd_chain(vnic_id),
        vnic_l2_iso_chain(vnic_id),
        vnic_l2_ref_chain(vnic_id)
      ],
      :l3 => [
        vnic_l3_main_chain(vnic_id),
        vnic_l3_stnd_chain(vnic_id),
        vnic_l3_iso_chain(vnic_id),
        vnic_l3_ref_chain(vnic_id),
        vnic_l3_secg_chain(vnic_id)
      ]
    }
  end
end
