# -*- coding: utf-8 -*-

require 'time'

require 'sinatra/base'
require 'sinatra/dcmgr_api_setup'
require 'sinatra/quota_evaluation'
require 'sinatra/internal_request'

require 'dcmgr/endpoints/errors'
require 'dcmgr/endpoints/12.03/quota_definitions'

module Dcmgr::Endpoints::V1203
  class CoreAPI < Sinatra::Base
    include Dcmgr::Logger
    register Sinatra::DcmgrAPISetup
    register Sinatra::InternalRequest
    register Sinatra::QuotaEvaluation

    # To access constants in this namespace
    include Dcmgr::Endpoints

    M = Dcmgr::Models
    E = Dcmgr::Endpoints::Errors
    R = Dcmgr::Endpoints::V1203::Responses

    include Dcmgr::Endpoints::Helpers

    before do
      requester_account_id = request.env[HTTP_X_VDC_ACCOUNT_UUID]
      if requester_account_id.nil?
        @account = nil
      else
        begin
          # find or create account entry.
          @account = M::Account[requester_account_id] || \
            M::Account.create(:uuid=>M::Account.trim_uuid(requester_account_id))
        rescue => e
          logger.error(e)
          raise E::InvalidRequestCredentials, "#{e.message}"
        end

        raise E::DisabledAccount if @account.disable?

        # Force overwrite the filtering parameter.
        params['account_id'] = @account.canonical_uuid
      end

      @requester_token = request.env[HTTP_X_VDC_REQUESTER_TOKEN]
    end

    # Common method to fetch single resource for PUT,DELETE
    # /resource/uuid request.
    #
    def find_by_uuid(model_class, uuid)
      if model_class.is_a?(Symbol)
        model_class = Dcmgr::Models.const_get(model_class, false)
      end
      raise E::InvalidParameter, "Invalid UUID Syntax: #{uuid}" if !model_class.valid_uuid_syntax?(uuid)
      item = model_class[uuid] || raise(E::UnknownUUIDResource, uuid.to_s)

      if item.class < M::AccountResource
        if @account && item.account_id != @account.canonical_uuid
          raise E::UnknownUUIDResource, uuid.to_s
        end
        if params[:service_type] && params[:service_type] != item.service_type
          raise E::UnknownUUIDResource, uuid.to_s
        end
      end
      item
    end

    def check_network_ip_combo(network_id,ip_addr)
      nw = M::Network[network_id]
      raise E::UnknownNetwork, network_id if nw.nil?

      if ip_addr
        raise E::InvalidIPAddress, ip_addr unless IPAddress.valid_ipv4?(ip_addr)

        leaseaddr = IPAddress(ip_addr)
        raise E::DuplicateIPAddress, ip_addr unless M::IpLease.filter(:ipv4 => leaseaddr.to_i).empty?

        segment = IPAddress("#{nw.ipv4_network}/#{nw.prefix}")
        raise E::IPAddressNotInSegment, ip_addr unless segment.include?(leaseaddr)

        raise E::IpNotInDhcpRange, ip_addr unless nw.exists_in_dhcp_range?(leaseaddr)
      end
    end

    def check_mac_addr(mac_addr)
      raise E::InvalidMacAddress, mac_addr if !(mac_addr.size == 12 && mac_addr =~ /^[0-9a-fA-F]{12}$/)
      raise E::DuplicateMacAddress, mac_addr if M::MacLease.is_leased?(mac_addr)

      # Check if this mac address exists in a defined range
      m_vid, m_a = M::MacLease.string_to_ints(mac_addr)
      raise E::MacNotInRange, mac_addr unless M::MacRange.exists_in_any_range?(m_vid,m_a)
    end

    def find_by_public_uuid(model_class, uuid)
      if model_class.is_a?(Symbol)
        model_class = Dcmgr::Models.const_get(model_class, false)
      end
      raise E::InvalidParameter, "Invalid UUID Syntax: #{uuid}" if !model_class.valid_uuid_syntax?(uuid)
      item = model_class[uuid] || raise(E::UnknownUUIDResource, uuid.to_s)

      if params[:service_type] && params[:service_type] != item.service_type
        raise E::UnknownUUIDResource, uuid.to_s
      end
      item
    end

    def validate_service_type(service_type)
      Dcmgr.conf.service_types[params[:service_type]] || raise(E::InvalidParameter, :service_type)
    end

    helpers do
      #
      #  - start
      #  - limit
      #  - sort_by
      def paging_params_filter(ds)

        total = ds.count

        start = if params[:start]
                  if params[:start] =~ /^\d+$/
                    params[:start].to_i
                  else
                    raise E::InvalidParameter, :start
                  end
                else
                  0
                end
        limit = if params[:limit]
                  if params[:limit] =~ /^\d+$/
                  params[:limit].to_i
                  else
                    raise E::InvalidParameter, :limit
                  end
                else
                  0
                end
        limit = limit < 1 ? 250 : limit

        ds = if params[:sort_by]
               params[:sort_by] =~ /^(\w+)(\.desc|\.asc)?$/
               ds.order(params[:sort_by])
             else
               ds.order(:id.desc)
             end

        ds = ds.limit(limit, start)
        [ds, total, start, limit]
      end

      # #{param}_since and #{param}_until
      def datetime_range_params_filter(param, ds)
        since_time = until_time = nil
        since_key = "#{param}_since"
        until_key = "#{param}_until"
        if params[since_key]
          since_time = begin
                         Time.iso8601(params[since_key].to_s).utc
                       rescue ArgumentError
                         raise E::InvalidParameter, since_key
                       end
        end
        if params[until_key]
          until_time = begin
                         Time.iso8601(params[until_key].to_s).utc
                       rescue ArgumentError
                         raise E::InvalidParameter, until_key
                       end
        end

        ds = if since_time && until_time
               if !(since_time < until_time)
                 raise E::InvalidParameter, "#{since_key} is larger than #{until_key}"
               end
               ds.filter("#{param}_at >= ?", since_time).filter("#{param}_at <= ?", until_time)
             elsif since_time
               ds.filter("#{param}_at >= ?", since_time)
             elsif until_time
               ds.filter("#{param}_at <= ?", until_time)
             else
               ds
             end
        ds
      end

      def collection_respond_with(ds, &blk)
        ds, total, start, limit  = paging_params_filter(ds)

        respond_with([{
                        :total => total,
                        :start => start,
                        :limit => limit,
                        :results=> blk.call(ds)
                      }])
      end
    end

    # default output format.
    respond_to :json, :yml

    load_namespace('instances')
    load_namespace('images')
    load_namespace('host_nodes')
    load_namespace('volumes')
    load_namespace('volume_snapshots')
    load_namespace('security_groups')
    load_namespace('storage_nodes')
    load_namespace('ssh_key_pairs')
    load_namespace('networks')
    load_namespace('network_vifs')
    load_namespace('dc_networks')
    load_namespace('reports')
    load_namespace('load_balancers')
    load_namespace('backup_storages')
    load_namespace('backup_objects')
    load_namespace('host_node_groups')
    load_namespace('storage_node_groups')
    load_namespace('network_groups')
    load_namespace('accounts')
  end
end
