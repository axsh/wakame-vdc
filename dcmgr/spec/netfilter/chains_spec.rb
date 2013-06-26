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
    @chains = {
      "iptables" => {
        # "chain_name" => {
          # "jumps" => [],
          # "tasks" => []
        # }
      },
      "ebtables" => {
        # "chain_name" => {
        #   "jumps" => [],
        #   "tasks" => []
        # }
      }
    }
  end

  def parse(cmds)
    cmds.each {|cmd|
      cmd.split(";").each { |semicolon_cmd|
        # p @chains["iptables"].keys
        # p @chains["ebtables"].keys
        # p semicolon_cmd
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
            raise "Jump target doesn't exit: #{bin} #{chain}" if @chains[bin][chain].nil?
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

  def l2_chains
    @parser.chains["ebtables"]
  end

  def l3_chains
    @parser.chains["iptables"]
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
  ["vdc_#{secg_id}_isolation"]
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
    "vdc_#{secg_id}_isolation"
  ]
end

describe "SGHandler and NetfilterAgent" do
  context "with 1 vnic, 1 host node, 1 security group" do
    let(:secg) { Fabricate(:secg) }
    let(:host) { Fabricate(:host_node) }
    let(:vnic) do
      Fabricate(:vnic, mac_addr: "525400033c48").tap do |n|
        n.add_security_group(secg)
        n.instance.host_node = host
        n.instance.save
      end
    end

    let(:handler) {SGHandlerTest.new.tap{|sgh| sgh.add_host(host)}}

    it "should create and delete chains" do
      handler.init_vnic(vnic.canonical_uuid)

      handler.nfa(host).l2_chains.keys.should =~ (
        l2_chains_for_vnic(vnic.canonical_uuid) + l2_chains_for_secg(secg.canonical_uuid)
      )
      handler.nfa(host).l3_chains.keys.should =~ (
        l3_chains_for_vnic(vnic.canonical_uuid) + l3_chains_for_secg(secg.canonical_uuid)
      )

      handler.destroy_vnic(vnic.canonical_uuid)
      vnic.destroy
      handler.nfa(host).l2_chains.should == {}
      handler.nfa(host).l3_chains.should == {}
    end
  end

  context "with 2 vnics, 1 host node, 1 security group" do
    let(:secg) { Fabricate(:secg) }
    let(:host) { Fabricate(:host_node) }
    let(:vnicA) do
      Fabricate(:vnic, mac_addr: "525400033c48").tap do |n|
        n.add_security_group(secg)
        n.instance.host_node = host
        n.instance.save
      end
    end

    let(:vnicB) do
      Fabricate(:vnic, mac_addr: "525400033c49").tap do |n|
        n.add_security_group(secg)
        n.instance.host_node = host
        n.instance.save
      end
    end

    let(:handler) {SGHandlerTest.new.tap{|sgh| sgh.add_host(host)}}

    it "should create and delete chains" do
      # Create vnic A
      handler.init_vnic(vnicA.canonical_uuid)

      handler.nfa(host).l2_chains.keys.should =~ (
        l2_chains_for_vnic(vnicA.canonical_uuid) + l2_chains_for_secg(secg.canonical_uuid)
      )
      handler.nfa(host).l3_chains.keys.should =~ (
        l3_chains_for_vnic(vnicA.canonical_uuid) + l3_chains_for_secg(secg.canonical_uuid)
      )

      # Create vnic B
      handler.init_vnic(vnicB.canonical_uuid)
      handler.nfa(host).l2_chains.keys.should =~ (
        l2_chains_for_vnic(vnicA.canonical_uuid) +
        l2_chains_for_vnic(vnicB.canonical_uuid) +
        l2_chains_for_secg(secg.canonical_uuid)
      )
      handler.nfa(host).l3_chains.keys.should =~ (
        l3_chains_for_vnic(vnicA.canonical_uuid) +
        l3_chains_for_vnic(vnicB.canonical_uuid) +
        l3_chains_for_secg(secg.canonical_uuid)
      )

      # Destroy vnic A
      handler.destroy_vnic(vnicA.canonical_uuid)
      vnicA.destroy
      handler.nfa(host).l2_chains.keys.should =~ (
        l2_chains_for_vnic(vnicB.canonical_uuid) +
        l2_chains_for_secg(secg.canonical_uuid)
      )
      handler.nfa(host).l3_chains.keys.should =~ (
        l3_chains_for_vnic(vnicB.canonical_uuid) +
        l3_chains_for_secg(secg.canonical_uuid)
      )

      # Destroy vnic B
      handler.destroy_vnic(vnicB.canonical_uuid)
      vnicB.destroy
      handler.nfa(host).l2_chains.should == {}
      handler.nfa(host).l3_chains.should == {}
    end
  end

  context "with 2 vnics, 1 host node, 2 security groups" do
    let(:host) { Fabricate(:host_node) }
    let(:groupA) { Fabricate(:secg) }
    let(:groupB) { Fabricate(:secg) }

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

    let(:handler) {SGHandlerTest.new.tap{|sgh| sgh.add_host(host)}}

    it "should create and delete chains" do
      handler.init_vnic(vnicA.canonical_uuid)
      handler.init_vnic(vnicB.canonical_uuid)

      handler.nfa(host).l2_chains.keys.should =~ (
        l2_chains_for_vnic(vnicA.canonical_uuid) +
        l2_chains_for_vnic(vnicB.canonical_uuid) +
        l2_chains_for_secg(groupA.canonical_uuid) +
        l2_chains_for_secg(groupB.canonical_uuid)
      )
      handler.nfa(host).l3_chains.keys.should =~ (
        l3_chains_for_vnic(vnicA.canonical_uuid) +
        l3_chains_for_vnic(vnicB.canonical_uuid) +
        l3_chains_for_secg(groupA.canonical_uuid) +
        l3_chains_for_secg(groupB.canonical_uuid)
      )

      handler.destroy_vnic(vnicB.canonical_uuid)
      vnicB.destroy
      handler.nfa(host).l2_chains.keys.should =~ (
        l2_chains_for_vnic(vnicA.canonical_uuid) +
        l2_chains_for_secg(groupA.canonical_uuid)
      )
      handler.nfa(host).l3_chains.keys.should =~ (
        l3_chains_for_vnic(vnicA.canonical_uuid) +
        l3_chains_for_secg(groupA.canonical_uuid)
      )

      handler.destroy_vnic(vnicA.canonical_uuid)
      vnicA.destroy
      handler.nfa(host).l2_chains.should == {}
      handler.nfa(host).l3_chains.should == {}
    end
  end
end
