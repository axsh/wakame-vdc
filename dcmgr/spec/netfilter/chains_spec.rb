# -*- coding: utf-8 -*-

require 'spec_helper'
require "ipaddr"

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
          if split_cmd[0] == "-j"
            target = split_cmd[1]
            raise "Jump target doesn't exit: #{bin} #{target}" if @chains[bin][target].nil?
            @chains[bin][chain]["jumps"] << target
          else
            @chains[bin][chain]["tasks"] << split_cmd.join(" ")
          end
        when "-X"
          chain = split_cmd.shift
          raise "Chain doesn't exist: #{bin} #{chain}" if @chains[bin][chain].nil?
          @chains[bin].each {|k,v|
            j = v["jumps"].member?(chain)
            raise "Tried to delete #{bin} chain '#{chain}' but chain '#{k}' still has a jump to it." if j
          }
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
    raise "Ebtables chain doesn't exit: '#{chain_name}'" if @parser.chains["ebtables"][chain_name].nil?
    @parser.chains["ebtables"][chain_name]["jumps"]
  end

  def l3chain_jumps(chain_name)
    raise "Iptables chain doesn't exit: '#{chain_name}'" if @parser.chains["iptables"][chain_name].nil?
    @parser.chains["iptables"][chain_name]["jumps"]
  end

  def l2chain_tasks(chain_name)
    raise "Ebtables chain doesn't exit: '#{chain_name}'" if @parser.chains["ebtables"][chain_name].nil?
    @parser.chains["ebtables"][chain_name]["tasks"]
  end

  def l3chain_tasks(chain_name)
    raise "Iptables chain doesn't exit: '#{chain_name}'" if @parser.chains["iptables"][chain_name].nil?
    @parser.chains["iptables"][chain_name]["tasks"]
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

RSpec::Matchers.define :have_applied_vnic do |vnic|
  chain :with_secgs do |secg_array|
    @groups = secg_array
  end

  match do |nfa|
    vnic_id = vnic.canonical_uuid
    @has_l2 = (nfa.l2chains & l2_chains_for_vnic(vnic_id)) == l2_chains_for_vnic(vnic_id)
    @has_l3 = (nfa.l3chains & l3_chains_for_vnic(vnic_id)) == l3_chains_for_vnic(vnic_id)

    #TODO: Failure message that shows which chains were missing
    if @groups
      l2iso_chain_jumps = @groups.map {|g| "vdc_#{g.canonical_uuid}_isolation"}
      l2ref_chain_jumps = @groups.map {|g| "vdc_#{g.canonical_uuid}_reffers"}
      l3iso_chain_jumps = @groups.map {|g| "vdc_#{g.canonical_uuid}_isolation"}
      l3ref_chain_jumps = @groups.map {|g| "vdc_#{g.canonical_uuid}_reffees"}
      l3sec_chain_jumps = @groups.map {|g| "vdc_#{g.canonical_uuid}_rules"}

      nfa.l2chain_jumps("vdc_#{vnic_id}_d_isolation").sort == l2iso_chain_jumps.sort &&
      nfa.l2chain_jumps("vdc_#{vnic_id}_d_reffers").sort == l2ref_chain_jumps.sort &&
      nfa.l3chain_jumps("vdc_#{vnic_id}_d_isolation").sort == l3iso_chain_jumps.sort &&
      nfa.l3chain_jumps("vdc_#{vnic_id}_d_security").sort == l3sec_chain_jumps.sort &&
      nfa.l3chain_jumps("vdc_#{vnic_id}_d_reffees").sort == l3ref_chain_jumps.sort &&
      @has_l2 && @has_l3
    else
      @has_l2 && @has_l3
    end
  end
end

RSpec::Matchers.define :have_applied_secg do |secg|
  chain :with_vnics do |vnic_array|
    @vnics = vnic_array
  end

  match do |nfa|
    secg_id = secg.canonical_uuid
    @has_l2 = (nfa.l2chains & l2_chains_for_secg(secg_id)).sort == l2_chains_for_secg(secg_id).sort
    @has_l3 = (nfa.l3chains & l3_chains_for_secg(secg_id)).sort == l3_chains_for_secg(secg_id).sort

    if @vnics
      @vnics.each {|v| raise "VNic '#{v.canonical_uuid}' doesn't have a direct ip lease." if v.direct_ip_lease.first.nil?}
      l2_iso_tasks = @vnics.map {|v| "--protocol arp --arp-opcode Request --arp-ip-src #{v.direct_ip_lease.first.ipv4} -j ACCEPT" }
      l3_iso_tasks = @vnics.map {|v| "-s #{v.direct_ip_lease.first.ipv4} -j ACCEPT"}

      nfa.l2chain_tasks("vdc_#{secg_id}_isolation").sort == l2_iso_tasks.sort &&
      nfa.l3chain_tasks("vdc_#{secg_id}_isolation").sort == l3_iso_tasks.sort &&
      @has_l2 && @has_l3
    else
      @has_l2 && @has_l3
    end
  end
end

RSpec::Matchers.define :have_nothing_applied do
  match do |nfa|
    nfa.l2chains == [] &&
    nfa.l3chains == []
  end
end

describe "SGHandler and NetfilterAgent" do
  # some syntax sugar
  def nfa(host)
    handler.nfa(host)
  end

  context "with 1 vnic, 1 host node, 1 security group" do
    let(:secg) { Fabricate(:secg) }
    let(:host) { Fabricate(:host_node) }
    let(:network) { Fabricate(:network) }
    let(:vnic) do
      Fabricate(:vnic, mac_addr: "525400033c48").tap do |n|
        n.add_security_group(secg)
        n.instance.host_node = host
        n.network = network
        n.save

        Dcmgr::Models::NetworkVifIpLease.create({
          :ipv4 => IPAddr.new("10.0.0.1").to_i,
          :network_id => network.id,
          :network_vif_id => n.id
        })

        n.instance.save
      end
    end
    let(:vnic_id) { vnic.canonical_uuid }

    let(:handler) {SGHandlerTest.new.tap{|sgh| sgh.add_host(host)}}


    it "should create and delete chains" do
      handler.init_vnic(vnic_id)

      nfa(host).should have_applied_vnic(vnic).with_secgs([secg])
      nfa(host).should have_applied_secg(secg).with_vnics([vnic])

      handler.destroy_vnic(vnic_id)
      vnic.destroy

      nfa(host).should_not have_applied_vnic(vnic)
      nfa(host).should_not have_applied_secg(secg)
      nfa(host).should have_nothing_applied
    end
  end

  context "with 2 vnics, 1 host node, 1 security group" do
    let(:secg) { Fabricate(:secg) }
    let(:host) { Fabricate(:host_node) }
    let(:network) { Fabricate(:network) }
    let(:vnicA) do
      Fabricate(:vnic, mac_addr: "525400033c48").tap do |n|
        n.add_security_group(secg)
        n.network = network
        n.save

        Dcmgr::Models::NetworkVifIpLease.create({
          :ipv4 => IPAddr.new("10.0.0.1").to_i,
          :network_id => network.id,
          :network_vif_id => n.id
        })

        n.instance.host_node = host
        n.instance.save
      end
    end
    let(:vnicA_id) {vnicA.canonical_uuid}

    let(:vnicB) do
      Fabricate(:vnic, mac_addr: "525400033c49").tap do |n|
        n.add_security_group(secg)
        n.network = network
        n.save

        Dcmgr::Models::NetworkVifIpLease.create({
          :ipv4 => IPAddr.new("10.0.0.2").to_i,
          :network_id => network.id,
          :network_vif_id => n.id
        })

        n.instance.host_node = host
        n.instance.save
      end
    end
    let(:vnicB_id) {vnicB.canonical_uuid}

    let(:handler) {SGHandlerTest.new.tap{|sgh| sgh.add_host(host)}}

    it "should create and delete chains" do
      # Create vnic A
      handler.init_vnic(vnicA_id)
      nfa(host).should have_applied_vnic(vnicA).with_secgs([secg])
      nfa(host).should have_applied_secg(secg).with_vnics([vnicA])

      # Create vnic B
      handler.init_vnic(vnicB_id)
      nfa(host).should have_applied_vnic(vnicA).with_secgs([secg])
      nfa(host).should have_applied_vnic(vnicB).with_secgs([secg])
      nfa(host).should have_applied_secg(secg).with_vnics([vnicA,vnicB])

      # Destroy vnic A
      handler.destroy_vnic(vnicA_id)
      vnicA.destroy
      nfa(host).should_not have_applied_vnic(vnicA)
      nfa(host).should have_applied_vnic(vnicB).with_secgs([secg])
      nfa(host).should have_applied_secg(secg).with_vnics([vnicB])

      # Destroy vnic B
      handler.destroy_vnic(vnicB_id)
      vnicB.destroy
      nfa(host).should have_nothing_applied
    end
  end

  context "with 2 vnics, 1 host node, 2 security groups" do
    let(:host) { Fabricate(:host_node) }
    let(:network) { Fabricate(:network) }
    let(:groupA) { Fabricate(:secg) }; let(:groupA_id) {groupA.canonical_uuid}
    let(:groupB) { Fabricate(:secg) }; let(:groupB_id) {groupB.canonical_uuid}

    let(:vnicA) do
      Fabricate(:vnic, mac_addr: "525400033c48").tap do |n|
        n.add_security_group(groupA)
        n.network = network
        n.save

        Dcmgr::Models::NetworkVifIpLease.create({
          :ipv4 => IPAddr.new("10.0.0.1").to_i,
          :network_id => network.id,
          :network_vif_id => n.id
        })

        n.instance.host_node = host
        n.instance.save
      end
    end
    let(:vnicB) do
      Fabricate(:vnic, mac_addr: "525400033c49").tap do |n|
        n.add_security_group(groupB)
        n.network = network
        n.save

        Dcmgr::Models::NetworkVifIpLease.create({
          :ipv4 => IPAddr.new("10.0.0.2").to_i,
          :network_id => network.id,
          :network_vif_id => n.id
        })

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

      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA])
      nfa(host).should have_applied_secg(groupA).with_vnics([vnicA])
      nfa(host).should have_applied_vnic(vnicB).with_secgs([groupB])
      nfa(host).should have_applied_secg(groupB).with_vnics([vnicB])

      handler.destroy_vnic(vnicB_id)
      vnicB.destroy

      nfa(host).should_not have_applied_vnic(vnicB)
      nfa(host).should_not have_applied_secg(groupB)
      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA])
      nfa(host).should have_applied_secg(groupA).with_vnics([vnicA])

      handler.destroy_vnic(vnicA_id)
      vnicA.destroy
      nfa(host).should have_nothing_applied
    end

    it "does live security group switching" do
      handler.init_vnic(vnicA_id)
      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA])

      handler.add_sgs_to_vnic(vnicA_id,[groupB_id])
      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA,groupB])

      handler.remove_sgs_from_vnic(vnicA_id,[groupB_id])
      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA])

      # Nothing should change, nor should there be an error if we try to remove a group we're not in
      handler.remove_sgs_from_vnic(vnicA_id,[groupB_id])
      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA])

      # vnicA is already in groupA but that shouldn't be a problem. groupA should just be ignored. That's what we're testing here.
      handler.add_sgs_to_vnic(vnicA_id,[groupA_id,groupB_id])
      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA,groupB])

      handler.remove_sgs_from_vnic(vnicA_id,[groupA_id,groupB_id])
      nfa(host).should have_applied_vnic(vnicA).with_secgs([])

      handler.add_sgs_to_vnic(vnicA_id,[groupA_id,groupB_id])
      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA,groupB])

      handler.destroy_vnic(vnicA_id)
      vnicA.destroy
      nfa(host).should have_nothing_applied
    end
  end

  context "with 3 vnics, 1 host node, 3 security groups" do
    let!(:host) { Fabricate(:host_node) }
    let(:network) { Fabricate(:network) }
    let!(:groupA) { Fabricate(:secg) }
    let!(:groupB) { Fabricate(:secg) }
    let!(:groupC) { Fabricate(:secg) }

    let!(:vnicA) do
      Fabricate(:vnic, mac_addr: "525400033c48").tap do |n|
        n.add_security_group(groupA)
        n.add_security_group(groupB)
        n.network = network
        n.save

        Dcmgr::Models::NetworkVifIpLease.create({
          :ipv4 => IPAddr.new("10.0.0.1").to_i,
          :network_id => network.id,
          :network_vif_id => n.id
        })

        n.instance.host_node = host
        n.instance.save
      end
    end
    let!(:vnicB) do
      Fabricate(:vnic, mac_addr: "525400033c49").tap do |n|
        n.add_security_group(groupC)
        n.network = network
        n.save

        Dcmgr::Models::NetworkVifIpLease.create({
          :ipv4 => IPAddr.new("10.0.0.2").to_i,
          :network_id => network.id,
          :network_vif_id => n.id
        })

        n.instance.host_node = host
        n.instance.save
      end
    end
    let!(:vnicC) do
      Fabricate(:vnic, mac_addr: "525400033c4a").tap do |n|
        n.add_security_group(groupB)
        n.add_security_group(groupC)
        n.network = network
        n.save

        Dcmgr::Models::NetworkVifIpLease.create({
          :ipv4 => IPAddr.new("10.0.0.3").to_i,
          :network_id => network.id,
          :network_vif_id => n.id
        })

        n.instance.host_node = host
        n.instance.save
      end
    end
    let(:vnicA_id) {vnicA.canonical_uuid}
    let(:vnicB_id) {vnicB.canonical_uuid}
    let(:vnicC_id) {vnicC.canonical_uuid}

    let(:handler) {SGHandlerTest.new.tap{|sgh| sgh.add_host(host)}}

    it "applies all netfilter settings for a host when calling init_host" do
      handler.init_host(host.node_id)

      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA,groupB])
      nfa(host).should have_applied_vnic(vnicB).with_secgs([groupC])
      nfa(host).should have_applied_vnic(vnicC).with_secgs([groupB,groupC])

      nfa(host).should have_applied_secg(groupA).with_vnics([vnicA])
      nfa(host).should have_applied_secg(groupB).with_vnics([vnicA,vnicC])
      nfa(host).should have_applied_secg(groupC).with_vnics([vnicB,vnicC])
    end
  end
end
