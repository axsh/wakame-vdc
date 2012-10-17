# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'sinatra/dcmgr_api_setup'

require 'dcmgr/endpoints/errors'

module Dcmgr::Endpoints::V1112
  class CoreAPI < Sinatra::Base
    include Dcmgr::Logger
    register Sinatra::DcmgrAPISetup

    use Dcmgr::Rack::RequestLogger

    M = Dcmgr::Models
    E = Dcmgr::Endpoints::Errors
    include Dcmgr::Endpoints

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
        model_class = Dcmgr::Models.const_get(model_class)
      end

      start = data[:start].to_i
      start = start < 1 ? 0 : start
      limit = data[:limit].to_i
      limit = limit < 1 ? nil : limit

      if %w(M::InstanceSpec).member?(model_class.to_s)
        total_ds = model_class.where(:account_id=>[@account.canonical_uuid,
                                                   M::Account::SystemAccount::SharedPoolAccount.uuid,
                                                  ])
      elsif [M::HostNode, M::StorageNode].member?(model_class)
        total_ds = model_class
      else
        total_ds = model_class.where(:account_id=>@account.canonical_uuid)
      end

      if [M::Instance, M::Volume, M::VolumeSnapshot].member?(model_class)
        total_ds = total_ds.alives_and_recent_termed
      end
      if %w(M::Image).member?(model_class.to_s)
        total_ds = total_ds.or(:is_public=>true)
      end

      partial_ds  = total_ds.dup.order(:id.desc)
      partial_ds = partial_ds.limit(limit, start) if limit.is_a?(Integer)

      results = partial_ds.all.map {|i|
        if [M::Image].member?(model_class)
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
    load_namespace('instance_specs')
  end
end
