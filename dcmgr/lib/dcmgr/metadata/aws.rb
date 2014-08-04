# -*- coding: utf-8 -*-

module Dcmgr::Metadata
  class AWS < MetadataType
    def get_items
      vnic = @inst[:instance_nics].first

      request_params = @inst[:request_params]
      instance_spec = request_params.respond_to?(:[]) && request_params[:instance_spec_id]

      # Appendix B: Metadata Categories
      # http://docs.amazonwebservices.com/AWSEC2/latest/UserGuide/index.html?AESDG-chapter-instancedata.html
      metadata_items = {
        'ami-id' => @inst[:image][:uuid],
        'ami-launch-index' => 0,
        'ami-manifest-path' => nil,
        'ancestor-ami-ids' => nil,
        'block-device-mapping/root' => '/dev/sda',
        'first-boot' => '', # Simple flag so windows instances know to generate a new password
        'hostname' => @inst[:hostname],
        'instance-action' => @inst[:state],
        'instance-id' => @inst[:uuid],
        'instance-type' => instance_spec || @inst[:image][:instance_model_name],
        'kernel-id' => nil,
        'local-hostname' => @inst[:hostname],
        'local-ipv4' => @inst[:ips].first,
        'mac' => vnic ? vnic[:mac_addr].unpack('A2'*6).join(':') : nil,
        'placement/availability-zone' => nil,
        'product-codes' => nil,
        'public-hostname' => @inst[:hostname],
        'public-ipv4'    => @inst[:nat_ips].first,
        'ramdisk-id' => nil,
        'reservation-id' => nil,
        'x-account-id' => @inst[:account_id]
      }

      @inst[:vif].each { |vnic|
        next if vnic[:ipv4].nil? or vnic[:ipv4][:network].nil?

        netaddr  = IPAddress::IPv4.new("#{vnic[:ipv4][:network][:ipv4_network]}/#{vnic[:ipv4][:network][:prefix]}")

        # vfat doesn't allow folder name including ":".
        # folder name including mac address replaces "-" to ":".
        mac = vnic[:mac_addr].unpack('A2'*6).join('-')
        metadata_items.merge!({
          "network/interfaces/macs/#{mac}/local-hostname" => @inst[:hostname],
          "network/interfaces/macs/#{mac}/local-ipv4s" => vnic[:ipv4][:address],
          "network/interfaces/macs/#{mac}/mac" => vnic[:mac_addr].unpack('A2'*6).join(':'),
          "network/interfaces/macs/#{mac}/public-hostname" => @inst[:hostname],
          "network/interfaces/macs/#{mac}/public-ipv4s" => vnic[:ipv4][:nat_address],
          "network/interfaces/macs/#{mac}/security-groups" => vnic[:security_groups].join(' '),
          # wakame-vdc extention items.
          # TODO: need an iface index number?
          "network/interfaces/macs/#{mac}/x-dns" => vnic[:ipv4][:network][:dns_server],
          "network/interfaces/macs/#{mac}/x-gateway" => vnic[:ipv4][:network][:ipv4_gw],
          "network/interfaces/macs/#{mac}/x-netmask" => netaddr.prefix.to_ip.to_s,
          "network/interfaces/macs/#{mac}/x-network" => vnic[:ipv4][:network][:ipv4_network],
          "network/interfaces/macs/#{mac}/x-broadcast" => netaddr.broadcast.to_s,
          "network/interfaces/macs/#{mac}/x-metric" => vnic[:ipv4][:network][:metric],
        })
      }

      Dcmgr::Configurations.hva.metadata.path_list.each {|k,v|
        metadata_items.merge!({"#{k}" => v})
      }

      if @inst[:ssh_key_data]
        metadata_items.merge!({
          "public-keys/0=#{@inst[:ssh_key_data][:uuid]}" => @inst[:ssh_key_data][:public_key],
          'public-keys/0/openssh-key'=> @inst[:ssh_key_data][:public_key],
        })
      else
        metadata_items.merge!({'public-keys/'=>nil})
      end
    end
  end
end
