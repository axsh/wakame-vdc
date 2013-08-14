# -*- coding: utf-8 -*-
require "ipaddress"

module Dcmgr::VNet::Netfilter::NetfilterAgent
  def self.included klass
    klass.class_eval do
      include Dcmgr::Logger
      attr_accessor :verbose_netfilter
    end
  end

  private
  def remove_all_chains
    prefix = Dcmgr::VNet::Netfilter::Chains::CHAIN_PREFIX
    logger.info "Removing all chains prefixed by '#{prefix}'."
    # We flush all chains first so there are no links left that would
    # prevent us from deleting them.

    # Delete forward and prerouting jumps
    #TODO: Write this cleaner... probably in ruby instead of bash
    ["iptables"].each { |bin|
      {:filter => :FORWARD, :nat => :PREROUTING}.each { |table,chain|
        system("
          #{bin} -t #{table} -L #{chain} --line-numbers | grep -q vdc_vif-
            while [ \"$?\" == \"0\" ]; do
            #{bin} -t #{table} -D #{chain} $(#{bin} -t #{table} -L #{chain} --line-numbers | grep -m 1 vdc_vif- | cut -d ' ' -f1)
            #{bin} -t #{table} -L #{chain} --line-numbers | grep -q vdc_vif-
          done
        ")
        system("for i in $(iptables -t #{table} -L | grep 'Chain #{prefix}' | cut -d ' ' -f2); do iptables -t #{table} -F $i; done")
        system("for i in $(iptables -t #{table} -L | grep 'Chain #{prefix}' | cut -d ' ' -f2); do iptables -t #{table} -X $i; done")
      }
    }

    # Flush 'em all
    system("for i in $(ebtables -L | grep 'Bridge chain: #{prefix}' | cut -d ' ' -f3 | cut -d ',' -f1); do ebtables -F; done")

    # Kill 'em all
    system("for i in $(ebtables -L | grep 'Bridge chain: #{prefix}' | cut -d ' ' -f3 | cut -d ',' -f1); do ebtables -X; done")
  end

  def apply_netfilter_cmds(cmds)
    cmds = [cmds] unless cmds.is_a?(Array)

    l2_cmds = []
    l3_cmds = []
    cmds.each { |c|
      case c.split(" ")[0]
      when "ebtables"
        l2_cmds << c
      when "iptables"
        l3_cmds << c
      end
    }

    if verbose_netfilter
      puts l2_cmds.join("\n")
      puts l3_cmds.join("\n")
    end

    system l2_cmds.join("\n")
    system l3_cmds.join("\n")
  end
end
