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

  def call_packetfilter_service(hn, method, *args)
    @hosts[hn.canonical_uuid].send(method, *args)
  end
end

class TestChain
  attr_accessor :name
  attr_accessor :jumps
  attr_accessor :rules

  def initialize(name = "")
    @name = name
    @jumps = []
    @rules = []
  end

  def add_jump(chain)
    raise "Chain '#{@name}' is already jumping to chain '#{chain.name}'" if has_jump?(chain)
    @jumps << chain
  end

  def has_jump?(chain)
    @jumps.member?(chain)
  end

  def add_rule(rule_string)
    @rules << rule_string
  end

  def flush
    @jumps = []
    @rules = []
  end
end

class NFCmdParser
  # attr_reader :chains
  attr_reader :l2chains
  attr_reader :l3chains

  def initialize
    # @chains = {"iptables" => {}, "ebtables" => {}}

    # Maps will have the format {"chain_name" => chain}
    # Using maps instead of arrays so I don't have to iterate when getting a specific chain
    @l2chains = {"FORWARD" => TestChain.new("FORWARD")}
    @l3chains = {"FORWARD" => TestChain.new("FORWARD")}
  end

  def is_empty?(bin)
    @l2chains.keys == ["FORWARD"] &&
    @l3chains.keys == ["FORWARD"]
  end

  def new_chain(bin, name)
    raise "Chain already exists: #{bin} #{name}." if chain_exists?(bin, name)
    chain_mapping(bin)[name] = TestChain.new(name)
  end

  def get_chain(bin, name)
    chain_mapping(bin)[name] || raise("Chain doesn't exist: #{bin} #{name}.")
  end

  def del_chain(bin, name)
    to_delete = get_chain(bin, name)
    all_chains(bin).values.each {|chain|
      raise "Tried to delete #{bin} chain '#{to_delete.name}' but chain '#{chain.name}' still has a jump to it." if chain.jumps.member?(to_delete)
    }
    all_chains(bin).delete to_delete.name
  end

  def chain_exists?(bin, name)
    !chain_mapping(bin)[name].nil?
  end

  def all_chains(bin)
    chain_mapping(bin)
  end

  def all_chain_names(bin)
    chain_mapping(bin).keys.sort
  end

  def parse(cmds)
    # puts cmds.join("\n")
    cmds.each {|cmd|
      cmd.split(";").each { |semicolon_cmd|
        split_cmd = semicolon_cmd.split(" ")
        bin = split_cmd.shift # Returns either "iptables" or "ebtables"

        case split_cmd.shift
        when "-N"
          new_chain(bin, split_cmd.shift)
        when "-A"
          c = get_chain(bin, split_cmd.shift)
          if split_cmd[0] == "-j"
            c.add_jump(split_cmd[1])
          else
            c.add_rule(split_cmd.join(" "))
          end
        when "-X"
          del_chain(bin, split_cmd.shift)
        when "-F"
          get_chain(bin, split_cmd.shift).flush
        when "-P"
          # We're setting policies. Do freakin' nuthin'
        else
          raise NotImplementedError, semicolon_cmd
        end
      }
    }
  end

  private
  def chain_mapping(bin)
    {"iptables" => @l2chains, "ebtables" => @l3chains}[bin]
  end
end

class NetfilterAgentTest
  include Dcmgr::Logger
  include Dcmgr::VNet::Netfilter::NetfilterAgent

  def initialize(*args)
    super *args
    @parser = NFCmdParser.new
  end

  def method_missing(method, *args)
    @parser.send(method, *args)
  end

  private
  def exec(cmds)
    cmds = [cmds] unless cmds.is_a?(Array)
    @parser.parse(cmds)
  end
end

# some syntax sugar
def nfa(host)
  handler.nfa(host)
end
