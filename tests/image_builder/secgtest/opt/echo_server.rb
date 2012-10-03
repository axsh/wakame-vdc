#!/usr/bin/env ruby
# encoding: utf-8
require 'socket'

# This is a little server for testing netfilter in wakame-vdc
# It listens on udp and tcp simultaniously and returns the ip
# of any client that sends a packet

DEFAULT_UDP_PORT = 999
DEFAULT_TCP_PORT = 999

ports = {}
ARGV.each { |arg|
  protocol, port = arg.split(":")
  ports[protocol] = port.to_i
}

ports["udp"] = DEFAULT_UDP_PORT if ports["udp"].nil?
ports["tcp"] = DEFAULT_TCP_PORT if ports["tcp"].nil?

BasicSocket.do_not_reverse_lookup = true

udp_thread = Thread.new(ports["udp"]) do |listen_port|
  udp = UDPSocket.new
  udp.bind('0.0.0.0', listen_port)
  loop do
    data, addr = udp.recvfrom(1024)
    port = addr[1]
    ip = addr[2]
    udp.send(ip, 0, ip, port)
  end
  client.close
end

tcp_thread = Thread.new(ports["tcp"]) do |listen_port|
  tcp = TCPserver.new('0.0.0.0', listen_port)
  while (session = tcp.accept)
    ip = session.peeraddr[2]
    session.print(ip)
  end
end

udp_thread.join
tcp_thread.join
