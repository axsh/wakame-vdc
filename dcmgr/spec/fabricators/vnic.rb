# -*- coding: utf-8 -*-
require 'ipaddress'

module DcmgrSpec::Fabricators
  Fabricator(:vnic, class_name: Dcmgr::Models::NetworkVif) do
    device_index 0
    account_id TEST_ACCOUNT
    instance { Fabricate(:instance) }
    before_save {|vnic, trancients| Dcmgr::Models::MacLease.create({:mac_addr => vnic.mac_addr.hex})}
  end

  def create_vnic(host, secgs, mac_addr, network, ipv4)
    Fabricate(:vnic, mac_addr: mac_addr).tap do |n|
      secgs.each {|sg| n.add_security_group(sg) }
      n.instance.host_node = host
      n.network = network
      n.save

      Dcmgr::Models::NetworkVifIpLease.create({
        :ipv4 => IPAddress::IPv4.new(ipv4).to_i,
        :network_id => n.network.id,
        :network_vif_id => n.id
      })

      n.instance.save
    end
  end
end
