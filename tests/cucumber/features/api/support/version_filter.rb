# -*- coding: utf-8 -*-

require File.expand_path('../../../step_definitons/step_helpers.rb', __FILE__)

TARGET_API_VER = ENV['API_VER'] || '12.03'


# The version comparison requires strings with the same number of
# dot-separated numbers. This requirement is strictly enforced in
# order to ensure the comparison operator is symmetric.
def api_ver_cmp(s, d)
  d_ary = d.split('.').map {|i| i.to_i }
  s_ary = s.split('.').map {|i| i.to_i }

  loop {
    return 0 if d_ary.empty? && s_ary.empty?

    case r=(s_ary.shift <=> d_ary.shift)
    when 1, -1
      return r
    end
  }
end

# Tag processing for API version based filtering.
#
# Syntax:
#   @api_from_vXX.XX
#   @api_until_vXX.XX
#
# XX.XX part represents the version number. ''@api_from_vXX.XX'' is
# applied to the feature/scenario that examine APIs for the version or
# later. In contrast, ''@api_until_vXX.XX'' is used to the
# feature/scenario they are obsolete from the version. 
#
# Example:
# @api_from_11.12
# Featrure: xxxxxxxxxxxxxxx
#   Scenario: xxxxx1
#
#   @api_until_11.12
#   Scenario: xxxxx2
#
#   @api_from_12.03
#   Scenario: xxxxx3
#
# When you run the cucumber command it accepts the ''API_VER'' environment
# variable.
#
#   % API_VER=11.12 cucumber test.feature
#
# It runs following scenarios:
#   - Scenario: xxxxx1
#   - Scenario: xxxxx2
#
# If you set the version number for next release, it should work as below.
# 
#   % API_VER=12.03 cucumber test.feature
#
# It runs following scenarios:
#   - Scenario: xxxxx1
#   - Scenario: xxxxx3
Around do |scenario, blk|
  from_vers = []
  until_vers = []
  scenario.source_tag_names.each { |t|
    next unless t =~ /^@(api_from|api_until)_v?([\d.]+)$/
    api_ver = $2

    if $1 == 'api_from'
      from_vers << $2
    else
      until_vers << $2
    end
  }

  from_vers.uniq!
  until_vers.uniq!

  if (!from_vers.empty? && api_ver_cmp(TARGET_API_VER, from_vers.max { |a,b| api_ver_cmp(a, b) }) < 0) ||
     (!until_vers.empty? && api_ver_cmp(TARGET_API_VER, until_vers.max { |a,b| api_ver_cmp(a, b) }) > 0)
    #puts "Skipping #{scenario.title} ..."
    next
  end

  APITest.api_ver(((TARGET_API_VER == '11.12') ? '' : TARGET_API_VER))
  blk.call
end

