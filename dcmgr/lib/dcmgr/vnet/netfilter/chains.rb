# -*- coding: utf-8 -*-

module Dcmgr::VNet::Netfilter::Chains
  CHAIN_PREFIX="vdc".freeze

  class Chain
    attr_accessor :name
    def self.binary(bin = nil)
      bin.nil? ? @binary : @binary = bin
    end

    def initialize(name, table = :filter)
      @name = name
      @table = table
    end

    def flush
      nf_cmd(:F)
    end

    def destroy
      nf_cmd(:F) + ";" + nf_cmd(:X)
    end

    def add_jump(target)
      nf_cmd(:A, "-j #{target.name}")
    end

    def del_jump(target)
      nf_cmd(:D, "-j #{target.name}")
    end

    def add_rule(rule)
      nf_cmd(:A, rule)
    end

    def del_rule(rule)
      nf_cmd(:D, rule)
    end

    def ==(chain)
      (chain.class == self.class) && (chain.name == self.name)
    end

    private
    def nf_cmd(action, cmd = "")
      "#{self.class.binary} -t #{@table} -#{action} #{@name} #{cmd}"
    end
  end

  class L2Chain < Chain
    binary "ebtables"
    def create
      nf_cmd(:N) + ";" + nf_cmd(:P, "RETURN")
    end
  end

  class L3Chain < Chain
    binary "iptables"
    def create
      nf_cmd(:N)
    end
  end

  def l2_forward_chain
    L2Chain.new("FORWARD")
  end

  def l3_forward_chain
    L3Chain.new("FORWARD")
  end

  def l3_nat_prerouting_chain
    L3Chain.new "PREROUTING", :nat
  end

  module Factory
    class << self
    def newchain(layer, suffix, table = :filter)
      raise "Layer must be either :L2 or :L3" unless layer == :L2 || layer == :L3
      Dcmgr::VNet::Netfilter::Chains.const_get("#{layer}Chain").new("#{CHAIN_PREFIX}_#{suffix}", table)
    end

    def vnic_chain(layer, vnic_id, suffix, table = :filter)
      newchain(layer, "#{vnic_id}_#{suffix}", table)
    end

    def secg_chain(layer, secg_id, suffix, table = :filter)
      newchain(layer, "#{secg_id}_#{suffix}", table)
    end
    end
  end

  module Inbound
    F = Dcmgr::VNet::Netfilter::Chains::Factory
    class << self
      def secg_l2_rules_chain(sg_id)
        F.secg_chain(:L2, sg_id, "d_rules")
      end

      def secg_l2_iso_chain(sg_id)
        F.secg_chain(:L2, sg_id, "isolation")
      end

      def secg_l2_ref_chain(sg_id)
        F.secg_chain(:L2, sg_id, "ref")
      end

      def secg_l3_rules_chain(sg_id)
        F.secg_chain(:L3, sg_id, "d_rules")
      end

      def secg_l3_iso_chain(sg_id)
        F.secg_chain(:L3, sg_id, "isolation")
      end

      def secg_l3_ref_chain(sg_id)
        F.secg_chain(:L3, sg_id, "ref")
      end

      def vnic_l2_main_chain(vnic_id)
        F.vnic_chain(:L2, vnic_id, "d")
      end

      def vnic_l2_iso_chain(vnic_id)
        F.vnic_chain(:L2, vnic_id, "d_isolation")
      end

      def vnic_l2_stnd_chain(vnic_id)
        F.vnic_chain(:L2, vnic_id, "d_standard")
      end

      def vnic_l2_ref_chain(vnic_id)
        F.vnic_chain(:L2, vnic_id, "d_ref")
      end

      # We need a rules chain for L2 as well because we have to accept
      # ARP from the ip addresses in the rules
      def vnic_l2_secg_chain(vnic_id)
        F.vnic_chain(:L2, vnic_id, "d_security")
      end

      def vnic_l3_main_chain(vnic_id)
        F.vnic_chain(:L3, vnic_id, "d")
      end

      def vnic_l3_stnd_chain(vnic_id)
        F.vnic_chain(:L3, vnic_id, "d_standard")
      end

      def vnic_l3_iso_chain(vnic_id)
        F.vnic_chain(:L3, vnic_id, "d_isolation")
      end

      def vnic_l3_ref_chain(vnic_id)
        F.vnic_chain(:L3, vnic_id, "d_ref")
      end

      def vnic_l3_secg_chain(vnic_id)
        F.vnic_chain(:L3, vnic_id, "d_security")
      end
    end
  end

  module Outbound
    F = Dcmgr::VNet::Netfilter::Chains::Factory
    class << self
      def vnic_l2_main_chain(vnic_id)
        F.vnic_chain(:L2, vnic_id, "s")
      end

      def vnic_l2_stnd_chain(vnic_id)
        F.vnic_chain(:L2, vnic_id, "s_standard")
      end

      def vnic_l3_main_chain(vnic_id)
        F.vnic_chain(:L3, vnic_id, "s")
      end

      # This chain is for the future implementation of outbound
      # security group rules.
      def vnic_l3_secg_chain(vnic_id)
        F.vnic_chain(:L3, vnic_id, "s_security")
      end

      def vnic_l3_dnat_chain(vnic_id)
        F.vnic_chain(:L3, vnic_id, "s_dnat", :nat)
      end

      def secg_l3_rules_chain(secg_id)
        F.secg_chain(:L3, secg_id, "s_rules")
      end
    end
  end

  O = Outbound
  I = Inbound

  def secg_chains(sg_id)
    [
      I.secg_l2_ref_chain(sg_id),
      I.secg_l2_rules_chain(sg_id),
      I.secg_l3_ref_chain(sg_id),
      I.secg_l3_rules_chain(sg_id),
      O.secg_l3_rules_chain(sg_id)
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
      I.vnic_l2_secg_chain(vnic_id)
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
      O.vnic_l3_secg_chain(vnic_id),
      O.vnic_l3_dnat_chain(vnic_id)
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
