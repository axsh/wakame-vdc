# -*- coding: utf-8 -*-

require 'extlib'
require 'sinatra/base'
require 'sinatra/sequel_transaction'
require 'yaml'
require 'json'

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
          ip = Models::IpLease.find(:ipv4=>src_ip)
          if ip.nil? || ip.instance_nic.nil?
            raise UnknownSourceIpError, src_ip
          end
          ip.instance_nic.instance
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
          pair = get_instance_from_ip(src_ip).ssh_key_pair_id
          return Models::SshKeyPair[pair].public_key unless pair.nil?
        end
        
        def security_groups(src_ip)
          get_instance_from_ip(src_ip).netfilter_groups.map { |grp|
            grp.name
          }.join("\n")
        end
        
        def user_data(src_ip)
          get_instance_from_ip(src_ip).user_data
        end
      end
    end
  end
end
