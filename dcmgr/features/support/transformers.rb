# -*- coding: utf-8 -*-

CAPTURE_A_NUMBER = Transform /^\d+$/ do |number|
  number.to_i
end

CAPTURE_A_STRING = Transform /^.+[^\s]$/ do |string|
  string
end
