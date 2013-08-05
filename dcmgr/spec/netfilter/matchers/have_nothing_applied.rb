# -*- coding: utf-8 -*-

RSpec::Matchers.define :have_nothing_applied do
  match do |nfa|
    !nfa.iptables.has_custom_chains? &&
    !nfa.ebtables.has_custom_chains? &&
    nfa.iptables.get_chain("FORWARD").jumps == [] &&
    nfa.iptables.get_chain("FORWARD").rules == [] &&
    nfa.ebtables.get_chain("FORWARD").jumps == [] &&
    nfa.ebtables.get_chain("FORWARD").rules == []
  end
end
