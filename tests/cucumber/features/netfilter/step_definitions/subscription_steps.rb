# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'

Before do
end

After do
end

Then /^we (should|should\snot) be subscribed to (.+)$/ do |outcome,event|
  parsed_event = event.gsub(/<Group (.+)>/) { |group|
    grp_name = group.split(" ").last
    variable_get_value "<registry:group_#{grp_name}"
  }


  retry_until(10) do
    system("rabbitmqctl list_queues | grep #{parsed_event} >> /dev/null")
    case outcome
      when "should"
        $? == 0
      when "should not"
        $? != 0
    end
  end
end
