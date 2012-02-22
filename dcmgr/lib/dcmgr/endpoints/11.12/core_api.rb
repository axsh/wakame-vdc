# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra/sequel_transaction'

require 'json'
require 'extlib/hash'

require 'dcmgr/endpoints/errors'

module Dcmgr::Endpoints::V1112
  class CoreAPI < Sinatra::Base
    include Dcmgr::Logger
    register Sinatra::Namespace
    register Sinatra::SequelTransaction

    use Dcmgr::Rack::RequestLogger

    disable :sessions
    disable :show_exceptions

    M = Dcmgr::Models
    E = Dcmgr::Endpoints::Errors
    include Dcmgr::Endpoints

    include Dcmgr::Endpoints::Helpers

    before do
      @params = parsed_request_body if request.post?
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

    before do
      Thread.current[M::BaseNew::LOCK_TABLES_KEY] = {}
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

    # Returns deserialized hash from HTTP body. Serialization fromat
    # is guessed from content type header. The query string params
    # is returned if none of content type header is in HTTP headers.
    # This method is called only when the request method is POST.
    def parsed_request_body
      # @mime_types should be defined by sinatra/respond_to.rb plugin.
      if @mime_types.nil?
        # use query string as requested params if Content-Type
        # header was not sent.
        # ActiveResource library tells the one level nested hash which has
        # {'something key'=>real_params} so that dummy key is assinged here.
        hash = {:dummy=>@params}
      else
        mime = @mime_types.first
        begin
          case mime.to_s
          when 'application/json', 'text/json'
            require 'json'
            hash = JSON.load(request.body)
            hash = hash.to_mash
          when 'application/yaml', 'text/yaml'
            require 'yaml'
            hash = YAML.load(request.body)
            hash = hash.to_mash
          else
            raise "Unsupported body document type: #{mime.to_s}"
          end
        rescue => e
          # fall back to query string params
          hash = {:dummy=>@params}
        end
      end
      return hash.values.first
    end

    def response_to(res)
      mime = @mime_types.first unless @mime_types.nil?
      case mime.to_s
      when 'application/yaml', 'text/yaml'
        content_type 'yaml'
        body res.to_yaml
      when 'application/xml', 'text/xml'
        raise NotImplementedError
      else
        content_type 'json'
        body res.to_json(JSON::PRETTY_STATE_PROTOTYPE)
      end
    end

    # I am not going to use error(ex, &blk) hook since it works only
    # when matches the Exception class exactly. I expect to match
    # whole subclasses of APIError so that override handle_exception!().
    def handle_exception!(boom)
      # Translate common non-APIError to APIError
      boom = case boom
             when Sequel::DatabaseError
               DatabaseError.new
             else
               boom
             end

      if boom.kind_of?(E::APIError)
        @env['sinatra.error'] = boom
        Dcmgr::Logger.create('API Error').error("#{request.path_info} -> #{boom.class.to_s}: #{boom.message} (#{boom.backtrace.nil? ? 'nil' : boom.backtrace.first})")
        error(boom.status_code, response_to({:error=>boom.class.to_s, :message=>boom.message, :code=>boom.error_code}))
      else
        logger.error(boom)
        super
      end
    end

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

    def self.load_namespace(ns)
      super(ns, binding)
    end
    
    load_namespace('11.12/instances')
    load_namespace('11.12/images')
    load_namespace('11.12/host_nodes')
    load_namespace('11.12/volumes')
    load_namespace('11.12/volume_snapshots')
    load_namespace('11.12/security_groups')
    load_namespace('11.12/storage_nodes')
    load_namespace('11.12/ssh_key_pairs')
    load_namespace('11.12/networks')
    load_namespace('11.12/instance_specs')
  end
end
