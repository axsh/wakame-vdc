# -*- coding: utf-8 -*-

module ChainMethods
  def succeed_with(msg)
    @fail_not_to = msg
    true
  end

  def fail_with(msg)
    @fail_should = msg
    false
  end

  def expect_chains(bin, chains)
    actual_chains = @nfa.send(bin).all_chain_names
    if (actual_chains & chains).sort == chains.sort
      succeed_with "There were chains applied that we expected not to.\n%s" %
        find_unexpected(chains, actual_chains)
    else
      fail_with "The chains we expected weren't applied.\n%s" %
        miss_expected(chains, actual_chains)
    end
  end

  def expect_rules_to_contain(bin, chain, rules)
    actual = @nfa.send(bin).get_chain(chain).rules
    expected = rules.sort

    if (actual & expected).sort == expected
      succeed_with "#{bin} chain '%s' had rules applied that we expected not to be.\n%s" %
        [chain, find_unexpected(expected, actual)]
    else
      fail_with "#{bin} chain '%s' didn't apply the rules we expected.\n%s" %
        [chain, miss_expected(expected, actual)]
    end
  end

  def expect_rules(bin, chain, rules)
    actual = @nfa.send(bin).get_chain(chain).rules.sort
    expected = rules.sort

    if actual == expected
      succeed_with "#{bin} chain '%s' had rules we expected it not to have.\n%s" %
        [chain, find_unexpected(expected, actual)]
    else
      fail_with "#{bin} chain '%s' didn't have the rules we expected.\n%s" %
        [chain, miss_expected(expected, actual)]
    end
  end

  def expect_nat_rules(chain, rules)
    actual = @nfa.iptables("nat").get_chain(chain).rules.sort
    expected = rules.sort

    if actual == expected
      succeed_with "iptables nat chain '%s' had rules we expected it not to have.\n%s" %
        [chain, find_unexpected(expected, actual)]
    else
      fail_with "iptables nat chain '%s' didn't have the rules we expected.\n%s" %
        [chain, miss_expected(expected, actual)]
    end
  end

  def expect_jumps(bin, chain, targets)
    actual = @nfa.send(bin).get_chain(chain).jumps.sort
    expected = targets.sort

    if actual == expected
      succeed_with "#{bin} chain '%s' had jumps we expected it not to have.\n%s" %
        [chain, find_unexpected(expected, actual)]
    else
      fail_with "#{bin} chain '%s' didn't have the jumps we expected.\n%s" %
        [chain, miss_expected(expected, actual)]
    end
  end

  def miss_expected(expected, got)
    "expected:\n  [#{expected.join(", ")}]\n" +
    "got:\n  [#{got.join(", ")}]\n" +
    "missed:\n  [#{(expected - got).join(", ")}]"
  end

  def find_unexpected(expected, got)
    "expected:\n  [#{expected.join(", ")}]\n" +
    "got:\n  [#{got.join(", ")}]\n" +
    "unexpected:\n  [#{(got - expected).join(", ")}]"
  end
end
