# -*- coding: utf-8 -*-

module Dcmgr::VNet::Netfilter::Chains
  CHAIN_PREFIX="vdc".freeze

  class Chain
    attr_accessor :name
    def self.binary(bin = nil)
      bin.nil? ? @binary : @binary = bin
    end

    def initialize(name)
      @name = name
    end

    def flush
      "#{self.class.binary} -F #{@name}"
    end

    def destroy
      "#{self.class.binary} -F #{@name}; #{self.class.binary} -X #{@name}"
    end

    def add_jump(target)
      "#{self.class.binary} -A #{@name} -j #{target.name}"
    end

    def del_jump(target)
      "#{self.class.binary} -D #{@name} -j #{target.name}"
    end

    def add_rule(rule)
      "#{self.class.binary} -A #{@name} #{rule}"
    end

    def del_rule(rule)
      "#{self.class.binary} -D #{@name} #{rule}"
    end

    def ==(chain)
      (chain.class == self.class) && (chain.name == self.name)
    end
  end

  class L2Chain < Chain
    binary "ebtables"
    def create
      "#{self.class.binary} -N #{@name}; ebtables -P #{@name} RETURN"
    end
  end

  class L3Chain < Chain
    binary "iptables"
    def create
      "#{self.class.binary} -N #{@name}"
    end
  end

  def l2_forward_chain
    L2Chain.new("FORWARD")
  end

  def l3_forward_chain
    L3Chain.new("FORWARD")
  end

  module Inbound
    class << self
      def secg_l3_rules_chain(sg_id)
        L3Chain.new("#{CHAIN_PREFIX}_#{sg_id}_rules")
      end

      def secg_l2_iso_chain(sg_id)
        L2Chain.new("#{CHAIN_PREFIX}_#{sg_id}_isolation")
      end

      def secg_l2_ref_chain(sg_id)
        L2Chain.new("#{CHAIN_PREFIX}_#{sg_id}_reffers")
      end

      def secg_l3_iso_chain(sg_id)
        L3Chain.new("#{CHAIN_PREFIX}_#{sg_id}_isolation")
      end

      def secg_l3_ref_chain(sg_id)
        L3Chain.new("#{CHAIN_PREFIX}_#{sg_id}_reffees")
      end

      def vnic_l2_main_chain(vnic_id)
        L2Chain.new("#{CHAIN_PREFIX}_#{vnic_id}_d")
      end

      def vnic_l2_iso_chain(vnic_id)
        L2Chain.new("#{CHAIN_PREFIX}_#{vnic_id}_d_isolation")
      end

      def vnic_l2_stnd_chain(vnic_id)
        L2Chain.new("#{CHAIN_PREFIX}_#{vnic_id}_d_standard")
      end

      def vnic_l2_ref_chain(vnic_id)
        L2Chain.new("#{CHAIN_PREFIX}_#{vnic_id}_d_reffers")
      end

      def vnic_l3_main_chain(vnic_id)
        L3Chain.new("#{CHAIN_PREFIX}_#{vnic_id}_d")
      end

      def vnic_l3_stnd_chain(vnic_id)
        L3Chain.new "#{CHAIN_PREFIX}_#{vnic_id}_d_standard"
      end

      def vnic_l3_iso_chain(vnic_id)
        L3Chain.new "#{CHAIN_PREFIX}_#{vnic_id}_d_isolation"
      end

      def vnic_l3_ref_chain(vnic_id)
        L3Chain.new "#{CHAIN_PREFIX}_#{vnic_id}_d_reffees" # Referencees was too long of a name for iptables (must be under 29 chars)
      end

      def vnic_l3_secg_chain(vnic_id)
        L3Chain.new "#{CHAIN_PREFIX}_#{vnic_id}_d_security" # Only L3 needs the secg chain. We don't have user defined L2 rules atm.
      end
    end
  end

  module Outbound
    class << self
      def vnic_l2_main_chain(vnic_id)
        L2Chain.new "#{CHAIN_PREFIX}_#{vnic_id}_s"
      end

      def vnic_l2_stnd_chain(vnic_id)
        L2Chain.new("#{CHAIN_PREFIX}_#{vnic_id}_s_standard")
      end

      def vnic_l3_main_chain(vnic_id)
        L3Chain.new "#{CHAIN_PREFIX}_#{vnic_id}_s"
      end

      # This chain is for the future implementation of outbound
      # security group rules.
      def vnic_l3_secg_chain(vnic_id)
        L3Chain.new "#{CHAIN_PREFIX}_#{vnic_id}_s_security"
      end
    end
  end

  O = Outbound
  I = Inbound

  def secg_chains(sg_id)
    [
      I.secg_l2_ref_chain(sg_id),
      I.secg_l3_ref_chain(sg_id),
      I.secg_l3_rules_chain(sg_id)
    ]
  end

  def isog_chains(ig_id)
    [I.secg_l2_iso_chain(ig_id), I.secg_l3_iso_chain(ig_id)]
  end

  def vnic_l2_inbound_chains(vnic_id)
    [
      I.vnic_l2_main_chain(vnic_id),
      I.vnic_l2_stnd_chain(vnic_id),
      I.vnic_l2_iso_chain(vnic_id),
      I.vnic_l2_ref_chain(vnic_id),
    ]
  end

  def vnic_l2_outbound_chains(vnic_id)
    [
      O.vnic_l2_main_chain(vnic_id),
      O.vnic_l2_stnd_chain(vnic_id)
    ]
  end

  def vnic_l2_chains(vnic_id)
    vnic_l2_inbound_chains(vnic_id) + vnic_l2_outbound_chains(vnic_id)
  end

  def vnic_l3_inbound_chains(vnic_id)
    [
      I.vnic_l3_main_chain(vnic_id),
      I.vnic_l3_stnd_chain(vnic_id),
      I.vnic_l3_iso_chain(vnic_id),
      I.vnic_l3_ref_chain(vnic_id),
      I.vnic_l3_secg_chain(vnic_id),
    ]
  end

  def vnic_l3_outbound_chains(vnic_id)
    [
      O.vnic_l3_main_chain(vnic_id),
      O.vnic_l3_secg_chain(vnic_id)
    ]
  end

  def vnic_l3_chains(vnic_id)
    vnic_l3_inbound_chains(vnic_id) + vnic_l3_outbound_chains(vnic_id)
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
    vnic_l2_chains(vnic_id) + vnic_l3_chains(vnic_id)
  end
end
