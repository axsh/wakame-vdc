# -*- coding: utf-8 -*-

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

  def del_jump(chain)
    raise "Chain '#{@name}' is not jumping to chain '#{chain.name}'" unless has_jump?(chain)
    @jumps.delete chain
  end

  def has_jump?(chain)
    @jumps.member?(chain)
  end

  def add_rule(rule_string)
    @rules << rule_string
  end

  def del_rule(rule_string)
    @rules.delete(rule_string) || raise("Rule doesn't exist in chain '#{@name}': '#{rule_string}'")
  end

  def flush
    @jumps = []
    @rules = []
  end
end

class Table

  def initialize
    @chains = @built_in_chains
  end

  def has_custom_chains?
    @chains.keys != @built_in_chains.keys
  end

  def new_chain(name)
    raise "Chain already exists: #{name}." if chain_exists?(name)
    @chains[name] = TestChain.new(name)
  end

  def get_chain(name)
    @chains[name] || raise("Chain doesn't exist: #{name}.")
  end

  def del_chain(name)
    to_delete = get_chain(name)
    raise "Tried to delete built in chain: '#{to_delete.name}'." if @built_in_chains.member?(to_delete)
    @chains.values.each {|chain|
      raise "Tried to delete chain '#{to_delete.name}' but chain '#{chain.name}' still has a jump to it." if chain.jumps.member?(to_delete)
    }
    @chains.delete to_delete.name
  end

  def chain_exists?(name)
    !@chains[name].nil?
  end

  def all_chain_names
    @chains.keys
  end

end

class Filter < Table
  # built_in_chains ["INPUT", "FORWARD", "OUTPUT"]
  def initialize
    @built_in_chains = {
      "INPUT" => TestChain.new("INPUT"),
      "FORWARD" => TestChain.new("FORWARD"),
      "OUTPUT" => TestChain.new("OUTPUT")
    }
    super
  end
end

class Nat < Table
  # built_in_chains ["PREROUTING", "POSTROUTING"]
  def initialize
    @built_in_chains = {
      "PREROUTING" => TestChain.new("PREROUTING"),
      "POSTROUTING" => TestChain.new("POSTROUTING"),
    }
    super
  end
end

class NFCmdParser

  def initialize
    flush
  end

  def flush
    @ebtables = {"filter" => Filter.new}
    @iptables = {"filter" => Filter.new, "nat" => Nat.new}
  end

  def ebtables(table = "filter")
    @ebtables[table]
  end

  def iptables(table = "filter")
    @iptables[table]
  end

  def parse(cmds)
    cmds.each {|cmd|
      cmd.split(";").each { |semicolon_cmd|
        split_cmd = semicolon_cmd.split(" ")
        bin = split_cmd.shift # Returns either "iptables" or "ebtables"

        table = if split_cmd[0] == "-t"
          split_cmd.shift
          split_cmd.shift
        else
          table = "filter"
        end

        case split_cmd.shift
        when "-N"
          send(bin, table).new_chain(split_cmd.shift)
        when "-A"
          c = send(bin, table).get_chain(split_cmd.shift)
          if split_cmd[0] == "-j"
            c.add_jump(split_cmd[1])
          else
            c.add_rule(split_cmd.join(" "))
          end
        when "-D"
          c = send(bin, table).get_chain(split_cmd.shift)
          if split_cmd[0] == "-j"
            c.del_jump(split_cmd[1])
          else
            c.del_rule(split_cmd.join(" "))
          end
        when "-X"
          send(bin, table).del_chain(split_cmd.shift)
        when "-F"
          send(bin, table).get_chain(split_cmd.shift).flush
        when "-P"
          # We're setting policies. Do freakin' nuthin'
        else
          raise NotImplementedError, semicolon_cmd
        end
      }
    }
  end

end
