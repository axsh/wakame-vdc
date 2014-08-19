# -*- coding: utf-8 -*-

module NetworkHelper
  def set_dhcp_range(network)
    nw_ipv4 = IPAddress::IPv4.new("#{network.ipv4_network}/#{network.prefix}")

    Fabricate(:dhcp_range, network: network,
                           range_begin: nw_ipv4.first,
                           range_end: nw_ipv4.last)
  end
end
