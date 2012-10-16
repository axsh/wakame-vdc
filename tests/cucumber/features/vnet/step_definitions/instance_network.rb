# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'

Before do
end

After do
end

Given /^the instance (.+) enables all network interfaces$/ do |arg_instance|
  instance = variable_get_value(arg_instance)

  ipaddr = APITest.get("/instances/#{instance}")["vif"].first["ipv4"]["address"]
  retry_until(60) do
    `echo | nc #{ipaddr} 22`
    $?.exitstatus == 0
  end

  ssh_pipe(instance, "ubuntu", "sudo -S bash") do |pipe|
    pipe.puts <<'_EOS_'
ubuntu
echo "auto eth1" >> /etc/network/interfaces
echo "iface eth1 inet dhcp" >> /etc/network/interfaces
echo "auto eth2" >> /etc/network/interfaces
echo "iface eth2 inet dhcp" >> /etc/network/interfaces
/etc/init.d/networking restart
_EOS_
    pipe.close_write
  end
end

Given /^instance (.+) enables (.+) network interface$/ do |arg_instance,arg_interface|
  instance = variable_get_value(arg_instance)
  interface = variable_get_value(arg_interface)

  ipaddr = APITest.get("/instances/#{instance}")["vif"].first["ipv4"]["address"]
  retry_until(60) do
    `echo | nc #{ipaddr} 22`
    $?.exitstatus == 0
  end

  ssh_pipe(instance, "ubuntu", "sudo -S bash") do |pipe|
    pipe.puts <<"_EOS_"
ubuntu
echo "auto #{interface}" >> /etc/network/interfaces
echo "iface #{interface} inet dhcp" >> /etc/network/interfaces
/etc/init.d/networking restart

export IP=`ip addr show #{interface} | grep -o 'inet [0-9]*.[0-9]*.[0-9]*.[0-9]*' | cut -f 2 -d ' '`
echo "Using IP address ${IP}."

route -n
route del default gw 10.102.0.1
route add 10.102.0.0 gw 10.102.0.1
route -n

_EOS_
    pipe.close_write
  end
end

When /^we ping from instance (.+) to instance (.+) over the network (.+)$/ do |arg_from,arg_to,arg_network|
  from_instance = variable_get_value(arg_from)
  to_instance = variable_get_value(arg_to)
  network = variable_get_value(arg_network)

  steps %Q{
    When the instance #{arg_from} is connected to the network #{arg_network} with the nic stored in <ping_from_instance:vif:>
      Then from <ping_from_instance:vif:> take {"ipv4":{"address":}} and save it to <ping_from_instance:vif:ipv4>

    When the instance #{arg_to} is connected to the network #{arg_network} with the nic stored in <ping_to_instance:vif:>
      Then from <ping_to_instance:vif:> take {"ipv4":{"address":}} and save it to <ping_to_instance:vif:ipv4>
  }

  ping_between_instances(from_instance, @registry['ping_from_instance:vif:ipv4'], @registry['ping_to_instance:vif:ipv4']).should be_true
end

When /^we ping from instance (.+) to ip (.+) over the network (.+)$/ do |arg_from,arg_to,arg_network|
  from_instance = variable_get_value(arg_from)
  to_ip = variable_get_value(arg_to)
  network = variable_get_value(arg_network)

  steps %Q{
    When the instance #{arg_from} is connected to the network #{arg_network} with the nic stored in <ping_from_instance:vif:>
      Then from <ping_from_instance:vif:> take {"ipv4":{"address":}} and save it to <ping_from_instance:vif:ipv4>
  }

  ping_between_instances(from_instance, @registry['ping_from_instance:vif:ipv4'], to_ip).should be_true
end
