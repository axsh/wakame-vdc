# -*- coding: utf-8 -*-


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

# some syntax sugar
def nfa(host)
  handler.nfa(host)
end
