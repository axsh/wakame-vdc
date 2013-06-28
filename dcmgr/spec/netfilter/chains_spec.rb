# -*- coding: utf-8 -*-

require 'spec_helper'

class SGHandlerTest
  include Dcmgr::Logger
  include Dcmgr::VNet::SGHandler

  def add_host(hn)
    @hosts ||= {}
    raise "Host already exists: #{hn.canonical_uuid}" if @hosts[hn.canonical_uuid]
    @hosts[hn.canonical_uuid] = NetfilterAgentTest.new
  end

  def get_netfilter_agent(hn)
    @hosts[hn.canonical_uuid]
  end
  alias :nfa :get_netfilter_agent

  def call_packetfilter_service(hn,method,*args)
    @hosts[hn.canonical_uuid].send(method,*args)
  end
end

class NFCmdParser
  attr_reader :chains

  def initialize
    @chains = {"iptables" => {}, "ebtables" => {}}
  end

  #TODO: Clean up this dirty hard to maintain format
  # I'm making the same mistake that I did with netfilter cache here

  #TODO: Raise error when trying to delete a chain that still has jumps to it
  def parse(cmds)
    # puts cmds.join("\n")
    cmds.each {|cmd|
      cmd.split(";").each { |semicolon_cmd|
        split_cmd = semicolon_cmd.split(" ")
        bin = split_cmd.shift # Returns either "iptables" or "ebtables"
        case split_cmd.shift
        when "-N"
          chain = split_cmd.shift
          raise "Chain already exists: #{bin} #{chain}" unless @chains[bin][chain].nil?
          @chains[bin][chain] = {"jumps" => [], "tasks" => []}
        when "-A"
          chain = split_cmd.shift
          raise "Chain doesn't exist: #{bin} #{chain}" if @chains[bin][chain].nil?
          if split_cmd.shift == "-j"
            target = split_cmd.shift
            raise "Jump target doesn't exit: #{bin} #{target}" if @chains[bin][target].nil?
            @chains[bin][chain]["jumps"] << target
          end
        when "-X"
          chain = split_cmd.shift
          raise "Chain doesn't exist: #{bin} #{chain}" if @chains[bin][chain].nil?
          @chains[bin].delete(chain)
        when "-F"
          chain = split_cmd.shift
          raise "Chain doesn't exist: #{bin} #{chain}" if @chains[bin][chain].nil?
          @chains[bin][chain] = {"jumps" => [], "tasks" => []}
        else
        end
      }
    }
  end
end

class NetfilterAgentTest
  include Dcmgr::Logger
  include Dcmgr::VNet::Netfilter::NetfilterAgent

  def initialize(*args)
    super *args
    @parser = NFCmdParser.new
  end

  def l2chains
    @parser.chains["ebtables"].keys
  end

  def l3chains
    @parser.chains["iptables"].keys
  end

  def l2chain_jumps(chain_name)
    @parser.chains["ebtables"][chain_name]["jumps"]
  end

  def l3chain_jumps(chain_name)
    @parser.chains["iptables"][chain_name]["jumps"]
  end

  private
  def exec(cmds)
    cmds = [cmds] unless cmds.is_a?(Array)
    @parser.parse(cmds)
  end
end

def l2_chains_for_vnic(vnic_id)
  [
    "vdc_#{vnic_id}_d",
    "vdc_#{vnic_id}_d_standard",
    "vdc_#{vnic_id}_d_isolation",
    "vdc_#{vnic_id}_d_reffers"
  ]
end

def l2_chains_for_secg(secg_id)
  ["vdc_#{secg_id}_reffers","vdc_#{secg_id}_isolation"]
end

def l3_chains_for_vnic(vnic_id)
  [
    "vdc_#{vnic_id}_d",
    "vdc_#{vnic_id}_d_standard",
    "vdc_#{vnic_id}_d_isolation",
    "vdc_#{vnic_id}_d_reffees",
    "vdc_#{vnic_id}_d_security",
  ]
end

def l3_chains_for_secg(secg_id)
  [
    "vdc_#{secg_id}_rules",
    "vdc_#{secg_id}_reffees",
    "vdc_#{secg_id}_isolation"
  ]
end

describe "SGHandler and NetfilterAgent" do
  # some syntax sugar
  def nfa(host)
    handler.nfa(host)
  end

  context "with 1 vnic, 1 host node, 1 security group" do
    let(:secg) { Fabricate(:secg) }; let(:secg_id) {secg.canonical_uuid}
    let(:host) { Fabricate(:host_node) }
    let(:vnic) do
      Fabricate(:vnic, mac_addr: "525400033c48").tap do |n|
        n.add_security_group(secg)
        n.instance.host_node = host
        n.instance.save
      end
    end
    let(:vnic_id) { vnic.canonical_uuid }

    let(:handler) {SGHandlerTest.new.tap{|sgh| sgh.add_host(host)}}


    it "should create and delete chains" do
      handler.init_vnic(vnic_id)

      nfa(host).l2chains.should =~ (l2_chains_for_vnic(vnic_id) + l2_chains_for_secg(secg_id))
      nfa(host).l2chain_jumps("vdc_#{vnic_id}_d").should =~ (l2_chains_for_vnic(vnic_id) - ["vdc_#{vnic_id}_d"])
      nfa(host).l2chain_jumps("vdc_#{vnic_id}_d_isolation").should =~ ["vdc_#{secg_id}_isolation"]
      nfa(host).l2chain_jumps("vdc_#{vnic_id}_d_reffers").should == ["vdc_#{secg_id}_reffers"]

      nfa(host).l3chains.should =~ (l3_chains_for_vnic(vnic_id) + l3_chains_for_secg(secg_id))
      nfa(host).l3chain_jumps("vdc_#{vnic_id}_d").should =~ (l3_chains_for_vnic(vnic_id) - ["vdc_#{vnic_id}_d"])
      nfa(host).l3chain_jumps("vdc_#{vnic_id}_d_isolation").should == ["vdc_#{secg_id}_isolation"]
      nfa(host).l3chain_jumps("vdc_#{vnic_id}_d_security").should == ["vdc_#{secg_id}_rules"]
      nfa(host).l3chain_jumps("vdc_#{vnic_id}_d_reffees").should == ["vdc_#{secg_id}_reffees"]

      handler.destroy_vnic(vnic_id)
      vnic.destroy
      handler.nfa(host).l2chains.should == []
      handler.nfa(host).l3chains.should == []
    end
  end

  context "with 2 vnics, 1 host node, 1 security group" do
    let(:secg) { Fabricate(:secg) }; let(:secg_id) {secg.canonical_uuid}
    let(:host) { Fabricate(:host_node) }
    let(:vnicA) do
      Fabricate(:vnic, mac_addr: "525400033c48").tap do |n|
        n.add_security_group(secg)
        n.instance.host_node = host
        n.instance.save
      end
    end
    let(:vnicA_id) {vnicA.canonical_uuid}

    let(:vnicB) do
      Fabricate(:vnic, mac_addr: "525400033c49").tap do |n|
        n.add_security_group(secg)
        n.instance.host_node = host
        n.instance.save
      end
    end
    let(:vnicB_id) {vnicB.canonical_uuid}

    let(:handler) {SGHandlerTest.new.tap{|sgh| sgh.add_host(host)}}

    it "should create and delete chains" do
      # Create vnic A
      handler.init_vnic(vnicA_id)

      nfa(host).l2chains.should =~ (l2_chains_for_vnic(vnicA_id) + l2_chains_for_secg(secg_id))
      nfa(host).l3chains.should =~ (
        l3_chains_for_vnic(vnicA_id) + l3_chains_for_secg(secg_id)
      )
      nfa(host).l2chain_jumps("vdc_#{vnicA_id}_d_isolation").should =~ l2_chains_for_secg(secg_id)
      nfa(host).l3chain_jumps("vdc_#{vnicA_id}_d_isolation").should =~ ["vdc_#{secg_id}_isolation"]
      nfa(host).l3chain_jumps("vdc_#{vnicA_id}_d_security").should =~ ["vdc_#{secg_id}_rules"]

      # Create vnic B
      handler.init_vnic(vnicB_id)
      nfa(host).l2chains.should =~ (l2_chains_for_vnic(vnicA_id) + l2_chains_for_vnic(vnicB_id) + l2_chains_for_secg(secg_id))
      nfa(host).l3chains.should =~ (l3_chains_for_vnic(vnicA_id) + l3_chains_for_vnic(vnicB_id) + l3_chains_for_secg(secg_id))
      nfa(host).l2chain_jumps("vdc_#{vnicB_id}_d_isolation").should =~ l2_chains_for_secg(secg_id)
      nfa(host).l3chain_jumps("vdc_#{vnicB_id}_d_isolation").should =~ ["vdc_#{secg_id}_isolation"]
      nfa(host).l3chain_jumps("vdc_#{vnicB_id}_d_security").should =~ ["vdc_#{secg_id}_rules"]

      # Destroy vnic A
      handler.destroy_vnic(vnicA_id)
      vnicA.destroy

      nfa(host).l2chains.should =~ (l2_chains_for_vnic(vnicB_id) + l2_chains_for_secg(secg_id))
      nfa(host).l3chains.should =~ (l3_chains_for_vnic(vnicB_id) + l3_chains_for_secg(secg_id))

      # Destroy vnic B
      handler.destroy_vnic(vnicB_id)
      vnicB.destroy
      nfa(host).l2chains.should == []
      nfa(host).l3chains.should == []
    end
  end

  context "with 2 vnics, 1 host node, 2 security groups" do
    let(:host) { Fabricate(:host_node) }
    let(:groupA) { Fabricate(:secg) }; let(:groupA_id) {groupA.canonical_uuid}
    let(:groupB) { Fabricate(:secg) }; let(:groupB_id) {groupB.canonical_uuid}

    let(:vnicA) do
      Fabricate(:vnic, mac_addr: "525400033c48").tap do |n|
        n.add_security_group(groupA)
        n.instance.host_node = host
        n.instance.save
      end
    end
    let(:vnicB) do
      Fabricate(:vnic, mac_addr: "525400033c49").tap do |n|
        n.add_security_group(groupB)
        n.instance.host_node = host
        n.instance.save
      end
    end
    let(:vnicA_id) {vnicA.canonical_uuid}
    let(:vnicB_id) {vnicB.canonical_uuid}

    let(:handler) {SGHandlerTest.new.tap{|sgh| sgh.add_host(host)}}

    it "should create and delete chains" do
      handler.init_vnic(vnicA_id)
      handler.init_vnic(vnicB_id)

      nfa(host).l2chains.should =~ (
        l2_chains_for_vnic(vnicA_id) + l2_chains_for_vnic(vnicB_id) +
        l2_chains_for_secg(groupA_id) + l2_chains_for_secg(groupB_id)
      )
      nfa(host).l3chains.should =~ (
        l3_chains_for_vnic(vnicA_id) + l3_chains_for_vnic(vnicB_id) +
        l3_chains_for_secg(groupA_id) + l3_chains_for_secg(groupB_id)
      )
      nfa(host).l2chain_jumps("vdc_#{vnicA_id}_d_isolation").should =~ l2_chains_for_secg(groupA_id)
      nfa(host).l3chain_jumps("vdc_#{vnicA_id}_d_isolation").should =~ ["vdc_#{groupA_id}_isolation"]
      nfa(host).l3chain_jumps("vdc_#{vnicA_id}_d_security").should =~ ["vdc_#{groupA_id}_rules"]

      nfa(host).l2chain_jumps("vdc_#{vnicB_id}_d_isolation").should =~ l2_chains_for_secg(groupB_id)
      nfa(host).l3chain_jumps("vdc_#{vnicB_id}_d_isolation").should =~ ["vdc_#{groupB_id}_isolation"]
      nfa(host).l3chain_jumps("vdc_#{vnicB_id}_d_security").should =~ ["vdc_#{groupB_id}_rules"]

      handler.destroy_vnic(vnicB_id)
      vnicB.destroy

      nfa(host).l2chains.should =~ (l2_chains_for_vnic(vnicA_id) + l2_chains_for_secg(groupA_id))
      nfa(host).l3chains.should =~ (l3_chains_for_vnic(vnicA_id) + l3_chains_for_secg(groupA_id))

      handler.destroy_vnic(vnicA_id)
      vnicA.destroy
      nfa(host).l2chains.should == []
      nfa(host).l3chains.should == []
    end

    it "does live security group switching" do
      handler.init_vnic(vnicA_id)

      handler.add_sgs_to_vnic(vnicA_id,[groupB_id])
      nfa(host).l2chain_jumps("vdc_#{vnicA_id}_d_isolation").should =~ (l2_chains_for_secg(groupA_id) + l2_chains_for_secg(groupB_id) )
      nfa(host).l3chain_jumps("vdc_#{vnicA_id}_d_isolation").should =~ ["vdc_#{groupA_id}_isolation","vdc_#{groupB_id}_isolation"]
      nfa(host).l3chain_jumps("vdc_#{vnicA_id}_d_security").should =~ ["vdc_#{groupA_id}_rules","vdc_#{groupB_id}_rules"]

      handler.remove_sgs_from_vnic(vnicA_id,[groupB_id])
      nfa(host).l2chain_jumps("vdc_#{vnicA_id}_d_isolation").should =~ l2_chains_for_secg(groupA_id)
      nfa(host).l3chain_jumps("vdc_#{vnicA_id}_d_isolation").should =~ ["vdc_#{groupA_id}_isolation"]
      nfa(host).l3chain_jumps("vdc_#{vnicA_id}_d_security").should =~ ["vdc_#{groupA_id}_rules"]

      # Nothing should change, nor should there be an error if we try to remove a group we're not in
      handler.remove_sgs_from_vnic(vnicA_id,[groupB_id])
      nfa(host).l2chain_jumps("vdc_#{vnicA_id}_d_isolation").should =~ l2_chains_for_secg(groupA_id)
      nfa(host).l3chain_jumps("vdc_#{vnicA_id}_d_isolation").should =~ ["vdc_#{groupA_id}_isolation"]
      nfa(host).l3chain_jumps("vdc_#{vnicA_id}_d_security").should =~ ["vdc_#{groupA_id}_rules"]

      # vnicA is already in groupA but that shouldn't be a problem. groupA should just be ignored. That's what we're testing here.
      handler.add_sgs_to_vnic(vnicA_id,[groupA_id,groupB_id])
      nfa(host).l2chain_jumps("vdc_#{vnicA_id}_d_isolation").should =~ (l2_chains_for_secg(groupA_id) + l2_chains_for_secg(groupB_id) )
      nfa(host).l3chain_jumps("vdc_#{vnicA_id}_d_isolation").should =~ ["vdc_#{groupA_id}_isolation","vdc_#{groupB_id}_isolation"]
      nfa(host).l3chain_jumps("vdc_#{vnicA_id}_d_security").should =~ ["vdc_#{groupA_id}_rules","vdc_#{groupB_id}_rules"]

      handler.remove_sgs_from_vnic(vnicA_id,[groupA_id,groupB_id])
      nfa(host).l2chain_jumps("vdc_#{vnicA_id}_d_isolation").should == []
      nfa(host).l3chain_jumps("vdc_#{vnicA_id}_d_isolation").should == []
      nfa(host).l3chain_jumps("vdc_#{vnicA_id}_d_security").should == []

      handler.add_sgs_to_vnic(vnicA_id,[groupA_id,groupB_id])
      nfa(host).l2chain_jumps("vdc_#{vnicA_id}_d_isolation").should =~ (l2_chains_for_secg(groupA_id) + l2_chains_for_secg(groupB_id) )
      nfa(host).l3chain_jumps("vdc_#{vnicA_id}_d_isolation").should =~ ["vdc_#{groupA_id}_isolation","vdc_#{groupB_id}_isolation"]
      nfa(host).l3chain_jumps("vdc_#{vnicA_id}_d_security").should =~ ["vdc_#{groupA_id}_rules","vdc_#{groupB_id}_rules"]

      handler.destroy_vnic(vnicA_id)
      vnicA.destroy
      nfa(host).l2chains.should == []
      nfa(host).l3chains.should == []
    end
  end
end
