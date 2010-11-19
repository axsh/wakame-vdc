# -*- coding: utf-8 -*-

require 'extlib'
require 'sinatra/base'
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

      disable :sessions
      disable :show_exceptions

      LATEST_PROVIDER_VER_ID='2010-11-01'
      
      get '/' do
        ''
      end

      get '/:version/metadata.*' do
      #get %r!\A/(\d{4}-\d{2}-\d{2})/metadata.(\w+)\Z! do
        v = params[:version]
        ext = params[:splat][0]
        v = case v
            when 'latest'
              LATEST_PROVIDER_VER_ID
            when /\A\d{4}-\d{2}-\d{2}\Z/
              v
            else
              raise "Invalid syntax in the version"  
            end
        v = v.gsub(/-/, '')
        
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
          ip = Models::IpLease.find(:ipv4=>src_ip)
          if ip.nil? || ip.instance_nic.nil?
            raise UnknownSourceIpError, src_ip
          end
          inst = ip.instance_nic.instance
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
      end

    end
  end
end
