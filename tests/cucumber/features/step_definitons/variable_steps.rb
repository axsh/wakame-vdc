# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end 
require 'cucumber/formatter/unicode'

Before do
  @registry = {}
end

After do
end

# Then (new) <registry:foo> should have {"network_id":} equal to "nw-demo2"
# Then (new) <registry:foo> should have {"count":} equal to 23
# Then (new) <registry:foo> should have {"attachment":} is a hash
# Then (new) <registry:foo> should have {"attachment":} equal to the following
#   || (?)
# Then (new) <registry:foo> should have {"attachment":} equal to {} (?)
# Then (new) <registry:foo> should have {"attachment":{"id":}} equal to <registry:bar>

# Then (new) <registry:foo> should have [{"network_id":}] equal to "nw-demo2"
# Then (new) <registry:foo> should have [{"network_id":},...] equal to "nw-demo2"

# Then (new) <registry:foo> should have [] equal to the following
#   | id | name |
#   |  1 | foo  |

def variable_get_value arg_value
  case arg_value
  when /^".*"$/
    arg_value[/^"(.*)"$/, 1]
  when /^[0-9]+$/
    arg_value.to_i
  when /^<.+>$/
    @registry[arg_value[/^<(.+)>$/, 1]]
  end
end

def variable_apply_template registry, template, operator
  case template
  when /^\{\}$/
    registry.kind_of?(Hash).should be_true
    operator.call(registry)

  when /^\[\]$/
    registry.kind_of?(Array).should be_true
    operator.call(registry)

  when /^\{"[^"]+":\}$/
    key = template[/^\{"([^"]+)":\}$/, 1]
    registry.has_key?(key).should be_true
    operator.call(registry[key])

  when /^\{"[^"]+":.+\}$/
    match = /^\{"([^"]+)":(.+)\}$/.match(template)
    registry.has_key?(match[1]).should be_true
    variable_apply_template(registry[match[1]], match[2], operator)

  when /^\[\.\.\.,.+,\.\.\.\]$/
    match = /^\[\.\.\.,(.+),\.\.\.\]$/.match(template)
    (registry.kind_of?(Array)).should be_true

    registry.find { |itr|
      variable_apply_template(itr, match[1], operator)
    }.nil? == false

  when /^\{\.\.\.,.+,\.\.\.\}$/
    match = /^\{\.\.\.,(.+),\.\.\.\}$/.match(template)
    (registry.kind_of?(Hash)).should be_true
    
    key = /^\{\.\.\.,\{\"(.+)\":\},\.\.\.\}$/.match(template)[1]
    if registry.has_key?(key)
      r = Hash.new
      r[key] = registry[key]
      variable_apply_template(r, match[1], operator)
    end
  when /^\[.+\]$/
    match = /^\[(.+)\]$/.match(template)
    (registry.kind_of?(Array) and registry.size == 1).should be_true
    variable_apply_template(registry.first, match[1], operator)

  when /^\[.+\].+$/
    match = /^\[(.+)\](.+)$/.match(template)
    (registry.kind_of?(Array)).should be_true
    variable_apply_template(registry[match[1].to_i], match[2], operator)
  end
end

Then /^<([^>]+)> [ ]*(should|should\snot) have (.+) (equal to|with a size of|with the key) (.+)$/ do |registry,outcome,template,arg_operator,arg_value|
  value = variable_get_value(arg_value)
  value.nil?.should be_false
  registry.nil?.should be_false

  operator =
    case arg_operator
    when 'equal to'
      Proc.new { |left| left == value }
    when 'with a size of'
      Proc.new { |left| left.size == value }
    when 'with the key'
      Proc.new { |left| left.has_key? value }
    end

  variable_apply_template(@registry[registry], template, operator).should == (outcome == 'should not' ? false : true)
end

Then /^from <([^>]+)> [ ]*take (.+) and save it to <([^>]+)>$/ do |registry,template,dest|
  operator = Proc.new { |right| @registry[dest] = right }
  variable_apply_template(@registry[registry], template, operator)
end

# Helper functions, move to appropriate file or make a hash relation
# between descriptons and registry keys.
Then /^the previous api call [ ]*(should|should\snot) have (.+) (equal to|with a size of|with the key) (.+)$/ do |outcome,template,operator,value|
  steps %Q{
    Then <api:latest> #{outcome} have #{template} #{operator} #{value}
  }  
end

Then /^from the previous api call [ ]*take (.+) and save it to <([^>]+)>$/ do |template,dest|
  steps %Q{
    Then from <api:latest> take #{template} and save it to <#{dest}>
  }  
end
