# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'

Before do
end

After do
end

require 'socket'
require 'timeout'

def is_port_open?(ip, port, protocol = :tcp, timeout = 10)
  begin
    Timeout::timeout(timeout) do
      begin
        case protocol
          when :tcp
            s = TCPSocket.new(ip, port)
          when :udp
            s = UDPSocket.new
            s.send("joske", 0, ip, port)
            s.recvfrom(1024)
          else
            raise ArgumentError,"Unsupported socket. Must be :tcp or :udp"
        end
        s.close
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        # Connection refused means we've gotten through the firewall
        return true
      end
    end
  rescue Timeout::Error
    # Timeout means we weren't able to get through the firewall
    return false
  end

  # No error means we've gotten through the firewall
  return true
end

Then /^we (should|should\snot) be able to make a (tcp|udp) connection on port (\d+) to the instance for (\d+) seconds$/ do |outcome, protocol, port, seconds|
  # Check if we know the instance's ip address yet
  inst_id = @api_call_results["create"]["instances"]["id"]
  while @api_call_results["get"]["instances/#{inst_id}"].nil? || @api_call_results["get"]["instances/#{inst_id}"]["vif"].nil?
    steps %Q{
      When we make an api get call to instances/#{inst_id} with no options
      Then the previous api call should be successful
    }
  end

  if outcome == "should"
    retry_until(seconds.to_f) do
      is_port_open?(@api_call_results["get"]["instances/#{inst_id}"]["vif"].first["ipv4"]["address"],port.to_i,protocol.to_sym)
    end
  else
    retry_while_not(seconds.to_f) do
      is_port_open?(@api_call_results["get"]["instances/#{inst_id}"]["vif"].first["ipv4"]["address"],port.to_i,protocol.to_sym)
    end
  end
end

When /^we successfully set the following rules for the security group$/ do |rules|
  rules_with_line_breaks = rules.inspect.slice(1,rules.inspect.length-2)
  steps %Q{
    When we make a successful api update call to security_groups/#{@api_call_results["create"]["security_groups"]["id"]} with the following options
    | rule |
    | #{rules_with_line_breaks} |
  }
end

When /^we successfully delete all rules from the security group$/ do
  steps %Q{
    When we successfully set the following rules for the security group
      """
      """
  }
end

Then /^we should not be able to ping the created instance for (\d+) seconds$/ do |seconds|
  retry_while_not(seconds.to_f) do
    ping(@api_call_results["create"]["instances"]["id"]).exitstatus == 0
  end
end

When /^we successfully start an instance of (.+) and (.+) with the new security group$/ do |image, spec|
  steps %Q{
    When we make a successful api create call to instances with the following options
      | image_id | instance_spec_id | ssh_key_id | security_groups                                         |
      | #{image} | #{spec}          | ssh-demo   | #{@api_call_results["create"]["security_groups"]["id"]} |
  }
end
