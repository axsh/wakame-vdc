# -*- coding: utf-8 -*-

require 'ipaddress'

module NetworkHelper
  def set_dhcp_range(network, r_begin = nil, r_end = nil)
    if r_begin.nil? || r_end.nil?
      nw_ipv4 = IPAddress::IPv4.new("#{network.ipv4_network}/#{network.prefix}")

      r_begin ||= nw_ipv4.first
      r_end ||= nw_ipv4.last
    end

    r_begin = ipv4_to_u32(r_begin) if r_begin.is_a?(String)
    r_end = ipv4_to_u32(r_end) if r_end.is_a?(String)

    Fabricate(:dhcp_range, network: network,
                           range_begin: r_begin,
                           range_end: r_end)
  end

  def ipv4_to_u32(ipv4)
    IPAddress::IPv4.new(ipv4).to_u32
  end
end
