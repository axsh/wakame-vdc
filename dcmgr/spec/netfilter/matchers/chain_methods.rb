# -*- coding: utf-8 -*-

module ChainMethods
  def succeed_with(msg)
    @fail_should_not = msg
    true
  end

  def fail_with(msg)
    @fail_should = msg
    false
  end

  def expect_chains(bin, chains)
    actual_chains = @nfa.send(bin).all_chain_names
    if (actual_chains & chains).sort == chains.sort
      succeed_with "There were chains applied that we expected not to.\n
      expected: [#{chains.join(", ")}]\n
      got: [#{actual_chains.join(", ")}]"
    else
      fail_with "The chains we expected weren't applied.\n
      expected: [#{chains.join(", ")}]\n
      got: [#{actual_chains.join(", ")}]"
    end
  end

  def expect_rules_to_contain(bin, chain, rules)
    actual = @nfa.send(bin).get_chain(chain).rules
    expected = rules.sort

    if (actual & expected).sort == expected
      succeed_with "#{bin} chain #{chain} had rules applied that we expected not to be.\n
      expected: [#{expected.join(", ")}]\n
      got: [#{actual.join(", ")}]"
    else
      fail_with "#{bin} chain #{chain} didn't apply the rules we expected.\n
      expected: [#{expected.join(", ")}]\n
      got: [#{actual.join(", ")}]"
    end
  end

  def expect_rules(bin, chain, rules)
    actual = @nfa.send(bin).get_chain(chain).rules.sort
    expected = rules.sort

    if actual == expected
      succeed_with "#{bin} chain '#{chain}' had rules we expected it not to have.\n
      rules: [#{actual.join(", ")}]"
    else
      fail_with "#{bin} chain '#{chain}' didn't have the rules we expected.\n
      expected: [#{expected.join(", ")}]\n
      got: [#{actual.join(", ")}]"
    end
  end

  def expect_nat_rules(chain, rules)
    actual = @nfa.iptables("nat").get_chain(chain).rules.sort
    expected = rules.sort

    if actual == expected
      succeed_with "iptables nat chain '#{chain}' had rules we expected it not to have.\n
      rules: [#{actual.join(", ")}]"
    else
      fail_with "iptables nat chain '#{chain}' didn't have the rules we expected.\n
      expected: [#{expected.join(", ")}]\n
      got: [#{actual.join(", ")}]"
    end
  end

  def expect_jumps(bin, chain, targets)
    actual = @nfa.send(bin).get_chain(chain).jumps.sort
    expected = targets.sort

    if actual == expected
      succeed_with "#{bin} chain '#{chain}' had jumps we expected it not to have.\n
      jumps: [#{actual.join(", ")}]"
    else
      fail_with "#{bin} chain '#{chain}' didn't have the jumps we expected.\n
      expected: [#{expected.join(", ")}]\n
      got: [#{actual.join(", ")}]"
    end
  end
end
