
require 'extlib'
require 'sinatra'
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
  module Web
    class Metadata < Sinatra::Base

      LATEST_PROVIDER_VER_ID='2010-03-01'
      
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
                     Module.find_const("::Dcmgr::Web::Metadata::Provider_#{v}").new.document(request.ip)
                   rescue NameError => e
                     raise e if e.is_a? NoMethodError
                     Dcmgr.logger.error("ERROR: Unsupported metadata version: #{v}")
                     Dcmgr.logger.error(e)
                     raise "Unsupported metadata version: #{v}"
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
        hash.map {|k,v|
          "#{k.to_s.upcase}='#{v}'"
        }.join("\n")
      end

      # Base class for Metadata provider
      class Provider
        # Each Metadata provider returns a Hash data for a VM along with the src_ip
        # @param [String] src_ip Source IP address who requested to the Meatadata service.
        # @return [Hash] Details for the VM
        def document(src_ip)
          raise NotImplementedError
        end
      end

      # 2010-03-01 version of metadata provider
      class Provider_20100301 < Provider
        def document(src_ip)
          inst = Models::Instance.find_by_assigned_ipaddr(src_ip)
          ret = {:instance_id=>"#{Models::Instance.prefix_uuid}-#{inst[:uuid]}"}
          # picks keys and values are duplicable from model obj.
          {:cpus=>:need_cpus,
            :cpu_mhz=>:need_cpu_mhz,
            :memory=>:need_memory,
            :account_id=>:account_id,
            :status=>:status}.each {|k1,k2|
            ret[k1] = inst[k2]
          }
          # IP address values
          ret[:ipaddrs] = inst.ip.map { |i|
            i[:ip]
          }
          ret
        end
      end

    end
  end
end
