# -*- coding: utf-8 -*-

require 'extlib'
require 'sinatra/base'
require 'sinatra/sequel_transaction'
require 'yaml'
require 'json'
require 'ipaddress'

require 'dcmgr'

# Metadata service endpoint for running VMs.
# The running VM can not identify itself that who or where i am. The service supplies these information from somewhere
# out of the VM. It publishes some very crucial information to each VM so that the access control to this service is
# mandated at both levels, the network and the application itself.
#
# The concept of the service is similar with Amazon EC2's Metadata service given via http://169.254.169.254/. The
# difference is the URI structure. This gives the single point URI as per below:
#   http://metadata.server/[version]/meatadata.[format]
# It will return a document which results in a syntax specified in the last extension field. The document contains
# over all information that the VM needs for self recoginition.
#
# see also
# http://docs.amazonwebservices.com/AWSEC2/latest/UserGuide/index.html?instancedata-data-categories.html

module Dcmgr
  module Endpoints
    class Metadata < Sinatra::Base
      include Dcmgr::Logger
      register Sinatra::SequelTransaction

      disable :sessions
      disable :show_exceptions

      LATEST_PROVIDER_VER_ID='2011-05-19'

      get '/' do
        ''
      end

      get '/:version/meta-data/:data' do
        get_data(params)
      end

      get '/:version/metadata.*' do
      #get %r!\A/(\d{4}-\d{2}-\d{2})/metadata.(\w+)\Z! do
        v = parse_version params[:version]
        ext = params[:splat][0]

        hash_doc = begin
                     self.class.find_const("Provider_#{v}").new.document(request.ip)
                   rescue NameError => e
                     raise e if e.is_a? NoMethodError
                     logger.error("ERROR: Unsupported metadata version: #{v}")
                     logger.error(e)
                     error(404, "Unsupported metadata version: #{v}")
                   rescue UnknownSourceIpError => e
                     error(404, "Unknown source IP: #{e.message}")
                   end

        return case ext
               when 'json'
                 JSON.dump(hash_doc)
               when 'sh'
                 shell_dump(hash_doc)
               when 'yaml'
                 YAML.dump(hash_doc)
               else
                 raise "Unsupported format: .#{ext}"
               end
      end

      private
      def get_data(params)
        v = parse_version params[:version]

        get_method = params[:data].gsub(/-/,'_')

        provider = begin
                     self.class.find_const("Provider_#{v}").new
                   rescue NameError => e
                     raise e if e.is_a? NoMethodError
                     logger.error("ERROR: Unsupported metadata version: #{v}")
                     logger.error(e)
                     error(404, "Unsupported metadata version: #{v}")
                   rescue UnknownSourceIpError => e
                     error(404, "Unknown source IP: #{e.message}")
                   end

        result = begin
                   provider.method(get_method).call(request.ip)
                 rescue NameError => e
                   raise e if e.is_a? NoMethodError
                   logger.error("ERROR: Unknown metadata: #{get_method}")
                   logger.error(e)
                   error(404, "Unknown metadata: #{get_method}")
                 end

        result
      end

      def parse_version(v)
        ret = case v
            when 'latest'
              LATEST_PROVIDER_VER_ID
            when /\A\d{4}-\d{2}-\d{2}\Z/
              v
            else
              raise "Invalid syntax in the version"
            end
        ret.gsub(/-/, '')
      end

      def shell_dump(hash)
        # TODO: values to be shell escaped
        hash.map {|k,v|
          "#{k.to_s.upcase}='#{v}'"
        }.join("\n")
      end

      class UnknownSourceIpError < StandardError; end

      # Base class for Metadata provider
      class Provider
        # Each Metadata provider returns a Hash data for a VM along with the src_ip
        # @param [String] src_ip Source IP address who requested to the Meatadata service.
        # @return [Hash] Details for the VM
        def document(src_ip)
          raise NotImplementedError
        end
      end

      # 2010-11-01 version of metadata provider
      class Provider_20101101 < Provider
        # {:cpu_cores=>1,
        #  :memory_size=>100,
        #  :state=>'running',
        #  :user_data=>'......',
        #  :network => [{
        #    :ip=>'192.168.1.1',
        #    :name=>'xxxxxx'
        #  }]
        # }
        def document(src_ip)
          inst = get_instance_from_ip(src_ip)
          ret = {
            :instance_id=>inst.canonical_uuid,
            :cpu_cores=>inst.cpu_cores,
            :memory_size=>inst.memory_size,
            :state => inst.state,
            :user_data=>inst.user_data.to_s,
          }
          # IP/network values
          ret[:network] = inst.nic.map { |nic|
            {:ip=>nic.ip.ipv4,
              :name=>nic.ip.network.name,
            }
          }
          ret[:volume] = inst.volume.map { |v|
          }
          ret
        end

        def get_instance_from_ip(src_ip)
          ip = Models::NetworkVifIpLease.find(:ipv4=>IPAddress::IPv4.new(src_ip).to_i, :deleted_at=>nil)
          if ip.nil? || ip.network_vif.nil?
            raise UnknownSourceIpError, src_ip
          end
          ip.network_vif.instance
        end
      end

      #This version implements compatibility with amazon EC2
      class Provider_20110519 < Provider_20101101
        def document(src_ip)
          inst = get_instance_from_ip(src_ip)
          ret = {
            :instance_id=>inst.canonical_uuid,
            :cpu_cores=>inst.cpu_cores,
            :memory_size=>inst.memory_size,
            :state => inst.state,
            :user_data=>inst.user_data.to_s,
          }
          # IP/network values
          ret[:network] = inst.nic.map { |nic|
            nic.ip.map { |ip|
              {:ip=>ip.ipv4,
                :uuid=>ip.network.canonical_uuid,
              }
            }
          }
          ret[:volume] = inst.volume.map { |v|
          }
          ret
        end

        # EC2 Functions not implemented yet
        # http://169.254.169.254/latest/meta-data/ami-launch-index
        # http://169.254.169.254/latest/meta-data/ami-manifest-path
        # http://169.254.169.254/latest/meta-data/ancestor-ami-ids
        # http://169.254.169.254/latest/meta-data/block-device-mapping
        # http://169.254.169.254/latest/meta-data/instance-type/instance-action
        # http://169.254.169.254/latest/meta-data/instance-type
        # http://169.254.169.254/latest/meta-data/kernel-id
        # http://169.254.169.254/latest/meta-data/placement/availability-zone
        # http://169.254.169.254/latest/meta-data/product-codes
        # http://169.254.169.254/latest/meta-data/placement
        # http://169.254.169.254/latest/meta-data/profile
        # http://169.254.169.254/latest/meta-data/public-hostname
        # http://169.254.169.254/latest/meta-data/ramdisk-id
        # http://169.254.169.254/latest/meta-data/reservation-id
        def wmi_id(src_ip)
          get_instance_from_ip(src_ip).image.cuuid
        end
        alias ami_id wmi_id

        def mac(src_ip)
          get_instance_from_ip(src_ip).nic.map { |nic|
            nic.pretty_mac_addr
          }.join("\n")
        end

        def network(src_ip)
          get_instance_from_ip(src_ip).nic.map { |nic|
            nic.ip.map { |ip|
              ip.network.cuuid
            }
          }.join("\n")
        end

        def instance_id(src_ip)
          get_instance_from_ip(src_ip).cuuid
        end

        def local_hostname(src_ip)
          get_instance_from_ip(src_ip).hostname
        end

        def local_ipv4(src_ip)
          get_instance_from_ip(src_ip).nic.map { |nic|
            nic.ip.map { |ip|
              unless ip.is_natted?
                ip.ipv4
              else
                nil
              end
            }.compact
          }.join("\n")
        end

        def public_ipv4(src_ip)
          get_instance_from_ip(src_ip).nic.map { |nic|
            nic.ip.map { |ip|
              if ip.is_natted?
                ip.ipv4
              else
                nil
              end
            }.compact
          }.join("\n")
        end

        def public_keys(src_ip)
          i = get_instance_from_ip(src_ip)
          # ssh_key_data is possible to be nil.
          i.ssh_key_data.nil? ? '' : i.ssh_key_data[:public_key]
        end

        def security_groups(src_ip)
          get_instance_from_ip(src_ip).security_groups.map { |grp|
            grp.canonical_uuid
          }.join("\n")
        end

        def user_data(src_ip)
          get_instance_from_ip(src_ip).user_data
        end
      end
    end

    class Ec2Metadata < Sinatra::Base
      include Dcmgr::Logger
      register Sinatra::SequelTransaction

      disable :sessions
      disable :show_exceptions

      API_VERSIONS = ['latest', '2011-01-01']
      TOP_LEVEL_ITEMS = ['meta-data', 'user-data' ]
      TOP_LEVEL_METADATA_ITEMS = [
                                  'ami-id',
                                  'ami-launch-index',
                                  'ami-manifest-path',
                                  'ancestor-ami-ids',
                                  'block-device-mapping/',
                                  'hostname',
                                  'instance-action',
                                  'instance-id',
                                  'instance-type',
                                  'kernel-id',
                                  'local-hostname',
                                  'local-ipv4',
                                  'mac',
                                  'network/',
                                  'placement/',
                                  'product-codes',
                                  'public-hostname',
                                  'public-ipv4',
                                  'public-keys/',
                                  'ramdisk-id',
                                  'reservation-id',
                                  'security-groups',
                                 ]

      get '/' do
        API_VERSIONS.join("\n")
      end

      get '/:version' do
        ''
      end

      get '/:version/' do
        TOP_LEVEL_ITEMS.join("\n")
      end

      get '/:version/user-data' do
        instance[:user_data]
      end

      get '/:version/meta-data/' do
        TOP_LEVEL_METADATA_ITEMS.join("\n")
      end

      get '/:version/meta-data/ami-id' do
        instance[:image][:uuid]
      end

      get '/:version/meta-data/ami-launch-index' do
        # TODO
        '0'
      end

      get '/:version/meta-data/ami-manifest-path' do
        # TODO
        ''
      end

      get '/:version/meta-data/ancestor-ami-ids' do
        # TODO
        ''
      end

      get '/:version/meta-data/block-device-mapping/' do
        # TODO
        'root'
      end

      get '/:version/meta-data/block-device-mapping/root' do
        # TODO
        '/dev/sda'
      end

      get '/:version/meta-data/hostname' do
        instance[:hostname]
      end

      get '/:version/meta-data/instance-action' do
        instance[:state]
      end

      get '/:version/meta-data/instance-id' do
        instance[:uuid]
      end

      get '/:version/meta-data/instance-type' do
        instance[:request_params][:instance_spec_id] || instance[:image][:instance_model_name]
      end

      get '/:version/meta-data/kernel-id' do
        # TODO
        ''
      end

      get '/:version/meta-data/local-hostname' do
        instance[:hostname]
      end

      get '/:version/meta-data/local-ipv4' do
        instance[:ips].first
      end

      get '/:version/meta-data/mac' do
        vnic = instance[:instance_nics].first || {}
        vnic[:mac_addr].unpack('A2'*6).join(':')
      end

      get '/:version/meta-data/network/' do
        'interfaces/'
      end

      get '/:version/meta-data/network/interfaces/' do
        'macs/'
      end

      get '/:version/meta-data/network/interfaces/macs/' do
        instance[:vif].map { |vnic|
          "#{vnic[:mac_addr].unpack('A2'*6).join(':')}/"
        }.join("\n")
      end

      get '/:version/meta-data/network/interfaces/macs/:mac/' do
        if vnic_mac?(params[:mac])
          [
           'local-hostname',
           'local-ipv4s',
           'mac',
           'public-hostname',
           'public-ipv4s',
           'security-groups',
           # wakame-vdc extention items.
           'x-gateway',
           'x-netmask',
           'x-network',
           'x-broadcast',
           'x-metric',
          ].join("\n")
        else
          # TODO
          ''
        end
      end

      get '/:version/meta-data/network/interfaces/macs/:mac/local-hostname' do
        if vnic_mac?(params[:mac])
          instance[:hostname]
        else
          ''
        end
      end

      get '/:version/meta-data/network/interfaces/macs/:mac/local-ipv4s' do
        if vnic_mac?(params[:mac])
          vnic = vnic(params[:mac])
          vnic[:ipv4][:address]
        else
          ''
        end
      end

      get '/:version/meta-data/network/interfaces/macs/:mac/mac' do
        if vnic_mac?(params[:mac])
          params[:mac]
        else
          ''
        end
      end

      get '/:version/meta-data/network/interfaces/macs/:mac/public-hostname' do
        if vnic_mac?(params[:mac])
          instance[:hostname]
        else
          # TODO
          ''
        end
      end

      get '/:version/meta-data/network/interfaces/macs/:mac/public-ipv4s' do
        if vnic_mac?(params[:mac])
          vnic = vnic(params[:mac])
          vnic[:ipv4][:nat_address]
        else
          ''
        end
      end

      get '/:version/meta-data/network/interfaces/macs/:mac/security-groups' do
        if vnic_mac?(params[:mac])
          instance[:security_groups].join("\n")
        else
          # TODO
          ''
        end
      end

      get '/:version/meta-data/network/interfaces/macs/:mac/x-gateway' do
        if vnic_mac?(params[:mac])
          vnic(params[:mac])[:ipv4][:network][:ipv4_gw]
        else
          ''
        end
      end

      get '/:version/meta-data/network/interfaces/macs/:mac/x-netmask' do
        if vnic_mac?(params[:mac])
          vnic = vnic(params[:mac])
          netaddr = IPAddress::IPv4.new("#{vnic[:ipv4][:network][:ipv4_network]}/#{vnic[:ipv4][:network][:prefix]}")
          netaddr.prefix.to_ip
        else
          ''
        end
      end

      get '/:version/meta-data/network/interfaces/macs/:mac/x-network' do
        if vnic_mac?(params[:mac])
          vnic = vnic(params[:mac])
          vnic[:ipv4][:network][:ipv4_network]
        else
          ''
        end
      end

      get '/:version/meta-data/network/interfaces/macs/:mac/x-broadcast' do
        if vnic_mac?(params[:mac])
          vnic = vnic(params[:mac])
          netaddr = IPAddress::IPv4.new("#{vnic[:ipv4][:network][:ipv4_network]}/#{vnic[:ipv4][:network][:prefix]}")
          netaddr.broadcast.to_s
        else
          ''
        end
      end

      get '/:version/meta-data/network/interfaces/macs/:mac/x-metric' do
        if vnic_mac?(params[:mac])
          vnic = vnic(params[:mac])
          vnic[:ipv4][:network][:metric].to_s
        else
          ''
        end
      end

      get '/:version/meta-data/placement/' do
        'availability-zone'
      end

      get '/:version/meta-data/placement/availability-zone' do
        # TODO
        ''
      end

      get '/:version/meta-data/product-codes' do
        # TODO
        ''
      end

      get '/:version/meta-data/public-hostname' do
        # TODO
        instance[:hostname]
      end

      get '/:version/meta-data/public-ipv4' do
        instance[:nat_ips]
      end

      get '/:version/meta-data/public-keys/' do
        ssh_key_data = instance[:ssh_key_data]
        ssh_key_data.nil? ? '' : [0, ssh_key_data[:uuid]].join("=")
      end

      get '/:version/meta-data/public-keys/0/' do
        ssh_key_data = instance[:ssh_key_data]
        ssh_key_data.nil? ? '' : 'openssh-key'
      end

      get '/:version/meta-data/public-keys/0/openssh-key' do
        ssh_key_data = instance[:ssh_key_data]
        # ssh_key_data is possible to be nil.
        ssh_key_data.nil? ? '' : ssh_key_data[:public_key]
      end

      get '/:version/meta-data/ramdisk-id' do
        # TODO
        ''
      end

      get '/:version/meta-data/reservation-id' do
        # TODO
        ''
      end

      get '/:version/meta-data/security-groups' do
        instance[:security_groups].join("\n")
      end

      private
      def instance
        ip = Models::NetworkVifIpLease.find(:ipv4 => IPAddress::IPv4.new(request.ip).to_i, :deleted_at=>nil)
        if ip.nil? || ip.network_vif.nil?
          raise UnknownSourceIpError, request.ip
        end
        ip.network_vif.instance.to_hash
      end

      def vnic_mac?(mac)
        if vnic(mac).size > 0
          true
        else
          false
        end
      end

      def vnic(mac)
        instance[:vif].map { |vnic|
          vnic if mac == vnic[:mac_addr].unpack('A2'*6).join(':')
        }.compact.first
      end

      class UnknownSourceIpError < StandardError; end

    end

  end
end
