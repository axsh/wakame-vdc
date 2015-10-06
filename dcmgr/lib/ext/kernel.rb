# -*- coding: utf-8 -*-

module Kernel
  def argument_type_check(argument,expected_class)
    raise ArgumentError, "Expected: '#{expected_class}'. Got: '#{argument.class}'" unless argument.is_a?(expected_class)
  end
end
