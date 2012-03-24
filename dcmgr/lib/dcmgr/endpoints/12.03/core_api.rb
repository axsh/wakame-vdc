# -*- coding: utf-8 -*-

require 'time'

require 'sinatra/base'
require 'sinatra/dcmgr_api_setup'

require 'dcmgr/endpoints/errors'

module Dcmgr::Endpoints::V1203
  class CoreAPI < Sinatra::Base
    include Dcmgr::Logger
    register Sinatra::DcmgrAPISetup

    use Dcmgr::Rack::RequestLogger

    # To access constants in this namespace
    include Dcmgr::Endpoints

    M = Dcmgr::Models
    E = Dcmgr::Endpoints::Errors
    R = Dcmgr::Endpoints::V1203::Responses

    include Dcmgr::Endpoints::Helpers

    before do
      if request.env[HTTP_X_VDC_ACCOUNT_UUID].to_s == ''
        raise E::InvalidRequestCredentials
      else
        begin
          # find or create account entry.
          @account = M::Account[request.env[HTTP_X_VDC_ACCOUNT_UUID]] || \
          M::Account.create(:uuid=>M::Account.trim_uuid(request.env[HTTP_X_VDC_ACCOUNT_UUID]))
        rescue => e
          logger.error(e)
          raise E::InvalidRequestCredentials, "#{e.message}"
        end
        raise E::InvalidRequestCredentials if @account.nil?
      end

      @requester_token = request.env[HTTP_X_VDC_REQUESTER_TOKEN]
      #@frontend = M::FrontendSystem[request.env[RACK_FRONTEND_SYSTEM_ID]]

      #raise E::InvalidRequestCredentials if !(@account && @frontend)
      raise E::DisabledAccount if @account.disable?
    end

    def find_by_uuid(model_class, uuid)
      if model_class.is_a?(Symbol)
        model_class = Dcmgr::Models.const_get(model_class)
      end
      model_class[uuid] || raise(E::UnknownUUIDResource, uuid.to_s)
    end

    def find_account(account_uuid)
      find_by_uuid(:Account, account_uuid)
    end

    alias :response_to :respond_with

    def find_volume_snapshot(snapshot_id)
      vs = M::VolumeSnapshot[snapshot_id]
      raise E::UnknownVolumeSnapshot if vs.nil?
      raise E::InvalidVolumeState unless vs.state.to_s == 'available'
      vs
    end

    def examine_owner(account_resource)
      if @account.canonical_uuid == account_resource.account_id ||
          @account.canonical_uuid == 'a-00000000'
        return true
      else
        return false
      end
    end

    def select_index(model_class, data)
      if model_class.is_a?(Symbol)
        model_class = M.const_get(model_class)
      end

      start = data[:start].to_i
      start = start < 1 ? 0 : start
      limit = data[:limit].to_i
      limit = limit < 1 ? nil : limit

      if [M::InstanceSpec.to_s].member?(model_class.to_s)
        total_ds = model_class.where(:account_id=>[@account.canonical_uuid,
                                                   M::Account::SystemAccount::SharedPoolAccount.uuid,
                                                  ])
      else
        total_ds = model_class.where(:account_id=>@account.canonical_uuid)
      end

      if [M::Instance.to_s, M::Volume.to_s, M::VolumeSnapshot.to_s].member?(model_class.to_s)
        total_ds = total_ds.alives_and_recent_termed
      end
      if [M::Image.to_s].member?(model_class.to_s)
        total_ds = total_ds.or(:is_public=>true)
      end

      partial_ds  = total_ds.dup.order(:id.desc)
      partial_ds = partial_ds.limit(limit, start) if limit.is_a?(Integer)

      results = partial_ds.all.map {|i|
        if [M::Image.to_s].member?(model_class.to_s)
          i.to_api_document(@account.canonical_uuid)
        else
          i.to_api_document
        end
      }

      res = [{
               :owner_total => total_ds.count,
               :start => start,
               :limit => limit,
               :results=> results
             }]
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
               ds.filter("#{param}_at" => since_time .. until_time)
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
  end
end
