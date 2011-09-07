# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'sinatra/rabbit'
require 'sinatra/sequel_transaction'

require 'json'
require 'extlib/hash'

require 'dcmgr/endpoints/errors'

module Dcmgr
  module Endpoints
    # HTTP Header constants for request credentials.
    HTTP_X_VDC_REQUESTER_TOKEN='HTTP_X_VDC_REQUESTER_TOKEN'.freeze
    HTTP_X_VDC_ACCOUNT_UUID='HTTP_X_VDC_ACCOUNT_UUID'.freeze

    RACK_FRONTEND_SYSTEM_ID='dcmgr.frotend_system.id'
    
    class CoreAPI < Sinatra::Base
      include Dcmgr::Logger
      register Sinatra::Rabbit
      register Sinatra::SequelTransaction

      use Dcmgr::Rack::RequestLogger

      disable :sessions
      disable :show_exceptions

      before do
        @params = parsed_request_body if request.post?
        if request.env[HTTP_X_VDC_ACCOUNT_UUID].to_s == ''
          raise InvalidRequestCredentials
        else
          begin
            # find or create account entry.
            @account = Models::Account[request.env[HTTP_X_VDC_ACCOUNT_UUID]] || \
                        Models::Account.create(:uuid=>Models::Account.trim_uuid(request.env[HTTP_X_VDC_ACCOUNT_UUID]))
          rescue => e
            logger.error(e)
            raise InvalidRequestCredentials, "#{e.message}"
          end
          raise InvalidRequestCredentials if @account.nil?
        end
         
        @requester_token = request.env[HTTP_X_VDC_REQUESTER_TOKEN]
        #@frontend = Models::FrontendSystem[request.env[RACK_FRONTEND_SYSTEM_ID]]

        #raise InvalidRequestCredentials if !(@account && @frontend)
        raise DisabledAccount if @account.disable?
      end

      before do
        Thread.current[Dcmgr::Models::BaseNew::LOCK_TABLES_KEY] = {}
      end

      def find_by_uuid(model_class, uuid)
        if model_class.is_a?(Symbol)
          model_class = Models.const_get(model_class)
        end
        model_class[uuid] || raise(UnknownUUIDResource, uuid.to_s)
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
          body res.to_json
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
        
        if boom.kind_of?(APIError)
          @env['sinatra.error'] = boom
          Dcmgr::Logger.create('API Error').error("#{request.path_info} -> #{boom.class.to_s}: #{boom.message} (#{boom.backtrace.first})")
          error(boom.status_code, response_to({:error=>boom.class.to_s, :message=>boom.message, :code=>boom.error_code}))
        else
          logger.error(boom)
          super
        end
      end

      def find_volume_snapshot(snapshot_id)
        vs = Models::VolumeSnapshot[snapshot_id]
        raise UnknownVolumeSnapshot if vs.nil?
        raise InvalidVolumeState unless vs.state.to_s == 'available'
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
          model_class = Models.const_get(model_class)
        end

        start = data[:start].to_i
        start = start < 1 ? 0 : start
        limit = data[:limit].to_i
        limit = limit < 1 ? nil : limit

        if %w(Dcmgr::Models::InstanceSpec).member?(model_class.to_s)
          total_ds = model_class.where(:account_id=>[@account.canonical_uuid,
                                                              Models::Account::SystemAccount::SharedPoolAccount.uuid,
                                                             ])
        else
          total_ds = model_class.where(:account_id=>@account.canonical_uuid)
        end
        
        if %w(Dcmgr::Models::Instance Dcmgr::Models::Volume Dcmgr::Models::VolumeSnapshot).member?(model_class.to_s)
          total_ds = total_ds.alives_and_recent_termed
        end
        if %w(Dcmgr::Models::Image).member?(model_class.to_s)
          total_ds = total_ds.or(:is_public=>true)
        end

        partial_ds  = total_ds.dup.order(:id.desc)
        partial_ds = partial_ds.limit(limit, start) if limit.is_a?(Integer)

        results = partial_ds.all.map {|i|
          if %w(Dcmgr::Models::Image).member?(model_class.to_s)
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

      # Endpoint to handle VM instance.
      collection :instances do
        operation :index do
          description 'Show list of instances'
          # params start, fixnum, optional 
          # params limit, fixnum, optional
          control do
            res = select_index(:Instance, {:start => params[:start],
                                 :limit => params[:limit]})
            response_to(res)
          end
        end

        operation :create do
          description 'Runs a new VM instance'
          # param :image_id, string, :required
          # param :instance_spec_id, string, :required
          # param :host_id, string, :optional
          # param :host_name, string, :optional
          # param :user_data, string, :optional
          # param :nf_group, array, :optional
          # param :ssh_key, string, :optional
          # param :network_id, string, :optional
          # param :ha_enabled, string, :optional
          control do
            Models::Instance.lock!
            
            wmi = Models::Image[params[:image_id]] || raise(InvalidImageID)
            spec = Models::InstanceSpec[params[:instance_spec_id]] || raise(InvalidInstanceSpec)

            instance = Models::Instance.entry_new(@account, wmi, spec, params.dup) do |i|
              # Set common parameters from user's request.
              # TODO: do not use rand() to decide vnc port.
              i.runtime_config = {:vnc_port=>rand(2000), :telnet_port=> (rand(2000) + 2000)}
              i.user_data = params[:user_data] || ''
              # set only when not nil as the table column has not null
              # condition.
              if params[:hostname]
                if Models::Instance::ValidationMethods.hostname_uniqueness(@account.canonical_uuid,
                                                                           params[:hostname])
                  i.hostname = params[:hostname]
                else
                  raise DuplicateHostname
                end
              end

              if params[:ssh_key]
                ssh_key_pair = Models::SshKeyPair.find(:account_id=>@account.canonical_uuid,
                                                       :name=>params[:ssh_key])
                if ssh_key_pair.nil?
                  raise UnknownSshKeyPair, "#{params[:ssh_key]}"
                else
                  i.set_ssh_key_pair(ssh_key_pair)
                end
              end

              if params[:ha_enabled] == 'true'
                i.ha_enabled = 1
              end
            end
            instance.save

            unless params[:nf_group].is_a?(Array)
              params[:nf_group] = ['default']
            end
            instance.join_nfgroup_by_name(@account.canonical_uuid, params[:nf_group])

            instance.state = :scheduling
            instance.save
            
            begin
              Scheduler.host_node.schedule(instance)
              Scheduler.network.schedule(instance)
              instance.save
            rescue Scheduler::SchedulerError
              instance.delete
              raise APIError, "Failed to schedule HostNode or Network"
            end
            
            instance.state = :pending
            instance.save

            case wmi.boot_dev_type
            when Models::Image::BOOT_DEV_SAN
              # create new volume from snapshot.
              snapshot_id = wmi.source[:snapshot_id]
              vs = find_volume_snapshot(snapshot_id)
              
              vol = Models::Volume.entry_new(@account.canonical_uuid, params.dup) do |v|
                if vs
                  v.snapshot_id = vs.canonical_uuid
                end
                v.boot_dev = 1
              end
              # assign instance -> volume
              vol.instance = instance
              vol.state = :scheduling
              vol.save

              begin 
                Scheduler.storage_node.schedule(vol)
                vol.save
              rescue Scheduler::SchedulerError
                instance.delete
                vol.delete
                raise APIError, "Failed to schedule storage node."
              end

              vol.state = :pending
              vol.save
              
              commit_transaction
              
              repository_address = Dcmgr::StorageService.repository_address(vs.destination_key)
              res = Dcmgr.messaging.submit("hva-handle.#{instance.host_pool.node_id}",
                                           'run_vol_store', instance.canonical_uuid, vol.canonical_uuid, repository_address)
            when Models::Image::BOOT_DEV_LOCAL
              commit_transaction
              res = Dcmgr.messaging.submit("hva-handle.#{instance.host_pool.node_id}",
                                           'run_local_store', instance.canonical_uuid)
            else
              raise "Unknown boot type"
            end
            Dcmgr.messaging.event_publish('instance.scheduled', :args=>[instance.canonical_uuid])
            
            response_to(instance.to_api_document)
          end
        end

        operation :show do
          #param :account_id, :string, :optional
          control do
            i = find_by_uuid(:Instance, params[:id])
            raise UnknownInstance if i.nil?
            
            response_to(i.to_api_document)
          end
        end

        operation :destroy do
          description 'Shutdown the instance'
          control do
            i = find_by_uuid(:Instance, params[:id])
            if examine_owner(i)
            else
              raise OperationNotPermitted
            end
            res = Dcmgr.messaging.submit("hva-handle.#{i.host_pool.node_id}", 'terminate', i.canonical_uuid)
            response_to([i.canonical_uuid])
          end
        end

        operation :reboot, :method=>:put, :member=>true do
          description 'Reboots the instance'
          control do
            i = find_by_uuid(:Instance, params[:id])
            Dcmgr.messaging.submit("hva-handle.#{i.host_pool.node_id}", 'reboot', i.canonical_uuid)
            response_to({})
          end
        end
      end

      collection :images do
        operation :create do
          description 'Register new machine image'
          control do
            Models::Image.lock!
            raise NotImplementedError
          end
        end

        operation :index do
          description 'Show list of machine images'
          control do
            res = select_index(:Image, {:start => params[:start],
                                 :limit => params[:limit]})
            response_to(res)
          end
        end

        operation :show do
          description "Show a machine image details."
          control do
            i = find_by_uuid(:Image, params[:id])
            if !(examine_owner(i) || i.is_public)
              raise OperationNotPermitted
            end
            response_to(i.to_api_document(@account.canonical_uuid))
          end
        end

        operation :destroy do
          description 'Delete a machine image'
          control do
            Models::Image.lock!
            i = find_by_uuid(:Image, params[:id])
            if examine_owner(i)
              i.delete
            else
              raise OperationNotPermitted
            end
            response_to([i.canonical_uuid])
          end
        end
      end
        
      collection :host_pools do
        operation :index do
          description 'Show list of host pools'
          control do
            res = select_index(:HostPool, {:start => params[:start],
                                 :limit => params[:limit]})
            response_to(res)
          end
        end

        operation :show do
          description 'Show status of the host'
          #param :account_id, :string, :optional
          control do
            hp = find_by_uuid(:HostPool, params[:id])
            raise OperationNotPermitted unless examine_owner(hp)
            
            response_to(hp.to_api_document)
          end
        end
      end

      collection :volumes do
        operation :index do
          description 'Show lists of the volume'
          # params start, fixnum, optional 
          # params limit, fixnum, optional
          control do
            res = select_index(:Volume, {:start => params[:start],
                                 :limit => params[:limit]})
            response_to(res)
          end
        end

        operation :show do
          description 'Show the volume status'
          # params id, string, required
          control do
            volume_id = params[:id]
            raise UndefinedVolumeID if volume_id.nil?
            v = find_by_uuid(:Volume, volume_id)
            response_to(v.to_api_document)
          end
        end

        operation :create do
          description 'Create the new volume'
          # params volume_size, string, required
          # params snapshot_id, string, optional
          # params storage_pool_id, string, optional
          control do
            Models::Volume.lock!
            sp = vs = vol = nil
            # input parameter validation
            if params[:snapshot_id]
              vs = find_volume_snapshot(params[:snapshot_id])
            elsif params[:volume_size]
              if !(Dcmgr.conf.create_volume_max_size.to_i >= params[:volume_size].to_i) ||
                  !(params[:volume_size].to_i >= Dcmgr.conf.create_volume_min_size.to_i)
                raise InvalidVolumeSize
              end
              if params[:storage_pool_id]
                sp = find_by_uuid(:StoragePool, params[:storage_pool_id])
                raise UnknownStoragePool if sp.nil?
                raise StoragePoolNotPermitted if sp.account_id != @account.canonical_uuid
              end
            else
              raise UndefinedRequiredParameter
            end

            vol = Models::Volume.entry_new(@account, params.dup) do |v|
              if vs
                v.snapshot_id = vs.canonical_uuid
              end
              if params[:volume_size]
                v.size = params[:volume_size].to_i
              end
            end
            vol.save

            if sp.nil?
              # going to storage node scheduling mode.
              vol.state = :scheduling
              vol.save

              begin
                e = nil
                begin
                  Scheduler.storage_node.schedule(vol)
                  vol.save
                rescue Scheduler::SchedulerError => e
                  raise APIError, "Could not be found storage server for new volume."
                rescue Models::Volume::CapacityError => e
                  raise OutOfDiskSpace
                end
              ensure
                if e
                  logger.error(e)
                  vol.delete
                end
              end

              vol.state = :pending
              vol.save
              
              commit_transaction
              
              repository_address = nil
              if vol.snapshot
                repository_address = Dcmgr::StorageService.repository_address(vol.snapshot.destination_key)
              end
              
              res = Dcmgr.messaging.submit("sta-handle.#{vol.storage_pool.node_id}", 'create_volume', vol.canonical_uuid, repository_address)
            else
              begin
                vol.storage_pool = sp
                vol.save
              rescue Models::Volume::CapacityError => e
                logger.error(e)
                raise OutOfDiskSpace
              end

              vol.state = :pending
              vol.save
              
              commit_transaction
              
              repository_address = nil
              if vol.snapshot
                repository_address = Dcmgr::StorageService.repository_address(vol.snapshot.destination_key)
              end
              
              res = Dcmgr.messaging.submit("sta-handle.#{vol.storage_pool.node_id}", 'create_volume', vol.canonical_uuid, repository_address)
            end

            response_to(vol.to_api_document)
          end
        end

        operation :destroy do
          description 'Delete the volume'
          # params id, string, required
          control do
            volume_id = params[:id]
            raise UndefinedVolumeID if volume_id.nil?
            
            vol = find_by_uuid(:Volume, volume_id)
            raise UnknownVolume if vol.nil?
            raise InvalidVolumeState unless vol.state == "available"

            begin
              v  = Models::Volume.delete_volume(@account.canonical_uuid, volume_id)
            rescue Models::Volume::RequestError => e
              logger.error(e)
              raise InvalidDeleteRequest
            end
            raise UnknownVolume if v.nil?

            commit_transaction
            res = Dcmgr.messaging.submit("sta-handle.#{v.storage_pool.node_id}", 'delete_volume', v.canonical_uuid)
            response_to([v.canonical_uuid])
          end
        end

        operation :attach, :method =>:put, :member =>true do
          description 'Attachd the volume'
          # params id, string, required
          # params instance_id, string, required
          control do
            raise UndefinedInstanceID if params[:instance_id].nil?
            raise UndefinedVolumeID if params[:id].nil?
            
            i = find_by_uuid(:Instance, params[:instance_id])
            raise UnknownInstance if i.nil?
            raise InvalidInstanceState unless i.live? && i.state == 'running'

            v = find_by_uuid(:Volume, params[:id])
            raise UnknownVolume if v.nil?
            raise AttachVolumeFailure, "Volume is attached to running instance." if v.instance

            v.instance = i
            v.save
            commit_transaction
            res = Dcmgr.messaging.submit("hva-handle.#{i.host_pool.node_id}", 'attach', i.canonical_uuid, v.canonical_uuid)

            response_to(v.to_api_document)
          end
        end

        operation :detach, :method =>:put, :member =>true do
          description 'Detachd the volume'
          # params id, string, required
          control do
            raise UndefinedVolumeID if params[:id].nil?

            v = find_by_uuid(:Volume, params[:id])
            raise UnknownVolume if v.nil?
            raise DetachVolumeFailure, "Volume is not attached to any instance." if v.instance.nil?
            # the volume as the boot device can not be detached.
            raise DetachVolumeFailure, "boot device can not be detached" if v.boot_dev == 1
            i = v.instance
            raise InvalidInstanceState unless i.live? && i.state == 'running'
            commit_transaction
            res = Dcmgr.messaging.submit("hva-handle.#{i.host_pool.node_id}", 'detach', i.canonical_uuid, v.canonical_uuid)
            response_to(v.to_api_document)
          end
        end

      end
      
      get '/api/volume_snapshots/upload_destination' do
        c = StorageService::snapshot_repository_config.dup
        tmp = c['local']
        c.delete('local')
        results = {}
        results = c.collect {|item| {
          :destination_id => item[0],
          :destination_name => item[1]["display_name"]
          }
        }
        results.unshift({
          :destination_id => 'local', 
          :destination_name => tmp['display_name']
        })
        response_to([{:results => results}])
      end
      
      collection :volume_snapshots do
        operation :index do
          description 'Show lists of the volume_snapshots'
          # params start, fixnum, optional 
          # params limit, fixnum, optional
          control do
            res = select_index(:VolumeSnapshot, {:start => params[:start],
                                 :limit => params[:limit]})
            response_to(res)
          end
        end

        operation :show do
          description 'Show the volume status'
          # params id, string, required
          control do
            snapshot_id = params[:id]
            raise UndefinedVolumeSnapshotID if snapshot_id.nil?
            vs = find_by_uuid(:VolumeSnapshot, snapshot_id)
            response_to(vs.to_api_document)
          end
        end

        operation :create do
          description 'Create a new volume snapshot'
          # params volume_id, string, required
          # params storage_pool_id, string, optional
          control do
            Models::Volume.lock!
            raise UndefinedVolumeID if params[:volume_id].nil?

            v = find_by_uuid(:Volume, params[:volume_id])
            raise UnknownVolume if v.nil?
            raise InvalidVolumeState unless v.ready_to_take_snapshot?
            vs = v.create_snapshot(@account.canonical_uuid)
            sp = vs.storage_pool
            destination_key = Dcmgr::StorageService.destination_key(@account.canonical_uuid, params[:destination], sp.snapshot_base_path, vs.snapshot_filename)
            vs.update_destination_key(@account.canonical_uuid, destination_key)
            commit_transaction
            
            repository_address = Dcmgr::StorageService.repository_address(destination_key)
            res = Dcmgr.messaging.submit("sta-handle.#{sp.node_id}", 'create_snapshot', vs.canonical_uuid, repository_address)
            response_to(vs.to_api_document)
          end
        end

        operation :destroy do
          description 'Delete the volume snapshot'
          # params id, string, required
          control do
            Models::VolumeSnapshot.lock!
            snapshot_id = params[:id]
            raise UndefindVolumeSnapshotID if snapshot_id.nil?
            
            v = find_by_uuid(:VolumeSnapshot, snapshot_id)
            raise UnknownVolumeSnapshot if v.nil?
            raise InvalidVolumeState unless v.state == "available"
            
            destination_key = v.destination_key
            
            begin
              vs  = Models::VolumeSnapshot.delete_snapshot(@account.canonical_uuid, snapshot_id)
            rescue Models::VolumeSnapshot::RequestError => e
              logger.error(e)
              raise InvalidDeleteRequest
            end
            raise UnknownVolumeSnapshot if vs.nil?
            sp = vs.storage_pool

            commit_transaction
             
            repository_address = Dcmgr::StorageService.repository_address(destination_key)
            res = Dcmgr.messaging.submit("sta-handle.#{sp.node_id}", 'delete_snapshot', vs.canonical_uuid, repository_address)
            response_to([vs.canonical_uuid])
          end
        end

      end

      collection :netfilter_groups do
        description 'Show lists of the netfilter_groups'
        operation :index do
          control do
            res = select_index(:NetfilterGroup, {:start => params[:start],
                                 :limit => params[:limit]})
            response_to(res)
          end
        end

        operation :show do
          description 'Show the netfilter_groups'
          control do
            g = find_by_uuid(:NetfilterGroup, params[:id])
            raise OperationNotPermitted unless examine_owner(g)

            response_to(g.to_api_document)
          end
        end

        operation :create do
          description 'Register a new netfilter_group'
          # params name, string
          # params description, string
          # params rule, string
          control do
            Models::NetfilterGroup.lock!
            raise UndefinedNetfilterGroup if params[:name].nil?

            @name = params[:name]
            # TODO: validate @name. @name can use [a-z] [A-Z] '_' '-'
            # - invalidate? -> raise InvalidCharacterOfNetfilterGroupName

            g = Models::NetfilterGroup.filter(:name => @name, :account_id => @account.canonical_uuid).first
            raise DuplicatedNetfilterGroup unless g.nil?

            g = Models::NetfilterGroup.create_group(@account.canonical_uuid, params)
            response_to(g.to_api_document)
          end
        end

        operation :update do
          description "Update parameters for the netfilter group"
          # params description, string
          # params rule, string
          control do
            g = find_by_uuid(:NetfilterGroup, params[:id])

            raise UnknownNetfilterGroup if g.nil?

            if params[:description]
              g.description = params[:description]
            end
            if params[:rule]
              g.rule = params[:rule]
            end

            g.save
            g.rebuild_rule

            commit_transaction
            # refresh netfilter_rules
            Dcmgr.messaging.event_publish('hva/netfilter_updated', :args=>[g.canonical_uuid])

            response_to(g.to_api_document)
          end
        end

        operation :destroy do
          # params name, string
          description "Delete the netfilter group"

          control do
            Models::NetfilterGroup.lock!
            g = find_by_uuid(:NetfilterGroup, params[:id])

            raise UnknownNetfilterGroup if g.nil?
            raise OperationNotPermitted unless examine_owner(g)

            # raise OperationNotPermitted if g.instances.size > 0
            begin
              g.destroy
            rescue => e
              # logger.error(e)
              raise OperationNotPermitted
            end

            response_to([g.canonical_uuid])
          end
        end

      end

      collection :netfilter_rules do
        operation :index do
          control do
          end
        end

        operation :show do
          description 'Show lists of the netfilter_rules'
          control do
            rules = []
            begin
              @name = params[:id]
              g = Models::NetfilterGroup.filter(:name => @name, :account_id => @account.canonical_uuid).first
              raise UnknownNetfilterGroup if g.nil?

              g.netfilter_rules.each { |rule|
                rules << rule.values
              }
            end

            response_to(rules)
          end
        end
      end

      collection :storage_pools do
        operation :index do
          description 'Show lists of the storage_pools'
          # params start, fixnum, optional
          # params limit, fixnum, optional
          control do
            res = select_index(:StoragePool, {:start => params[:start],
                                 :limit => params[:limit]})
            response_to(res)
          end
        end

        operation :show do
          description 'Show the storage_pool status'
          # params id, string, required
          control do
            pool_id = params[:id]
            raise UndefinedStoragePoolID if pool_id.nil?
            vs = find_by_uuid(:StoragePool, pool_id)
            raise UnknownStoragePool if vs.nil?
            response_to(vs.to_api_document)
          end
        end
      end

      collection :ssh_key_pairs do
        description "List ssh key pairs in account"
        operation :index do
          # params start, fixnum, optional 
          # params limit, fixnum, optional
          control do
            res = select_index(:SshKeyPair, {:start => params[:start],
                                 :limit => params[:limit]})
            response_to(res)
          end
        end
        
        operation :show do
          description "Retrieve details about ssh key pair"
          # params :id required
          # params :format optional [openssh,putty]
          control do
            ssh = find_by_uuid(:SshKeyPair, params[:id])
            
            response_to(ssh.to_api_document)
          end
        end
        
        operation :create do
          description "Create ssh key pair information"
          # params :name required key name (<100 chars)
          # params :download_once optional set true if you do not want
          #        to save private key info on database.
          control do
            Models::SshKeyPair.lock!
            keydata = Models::SshKeyPair.generate_key_pair
            savedata = {
              :name=>params[:name],
              :account_id=>@account.canonical_uuid,
              :public_key=>keydata[:public_key],
              :finger_print => keydata[:finger_print],
            }
            if params[:download_once] != 'true'
              savedata[:private_key]=keydata[:private_key]
            end
            
            if !Models::SshKeyPair.filter(:account_id=>@account.canonical_uuid,
                                          :name => params[:name]).empty?
              raise DuplicateSshKeyName, params[:name]
            end
              
            begin
              ssh = Models::SshKeyPair.create(savedata)
            rescue => e
              raise DatabaseError, e.message
            end
                                            
            # include private_key data in response even if
            # it's not going to be stored on DB.
            response_to(ssh.to_api_document.merge(:private_key=>keydata[:private_key]))
          end
        end
        
        operation :destroy do
          description "Remove ssh key pair information"
          # params :id required
          control do
            Models::SshKeyPair.lock!
            ssh = find_by_uuid(:SshKeyPair, params[:id])
            if examine_owner(ssh)
              ssh.destroy
            else
              raise OperationNotPermitted
            end
            
            response_to([ssh.canonical_uuid])
          end
        end

      end

      collection :networks do
        description "Networks for account"
        operation :index do
          description "List networks in account"
          # params start, fixnum, optional 
          # params limit, fixnum, optional
          control do
            res = select_index(:Network, {:start => params[:start],
                                 :limit => params[:limit]})
            response_to(res)
          end
        end
        
        operation :show do
          description "Retrieve details about a network"
          # params :id required
          control do
            nw = find_by_uuid(:Network, params[:id])
            examine_owner(nw) || raise(OperationNotPermitted)
            
            response_to(nw.to_api_document)
          end
        end
        
        operation :create do
          description "Create new network"
          # params :gw required default gateway address of the network
          # params :prefix optional  netmask bit length. it will be
          #               set 24 if none.
          # params :description optional description for the network
          control do
            Models::Network.lock!
            savedata = {
              :account_id=>@account.canonical_uuid,
              :ipv4_gw => params[:gw],
              :prefix => params[:prefix].to_i,
              :description => params[:description],
            }
            nw = Models::Network.create(savedata)
                                            
            response_to(nw.to_api_document)
          end
        end
        
        operation :destroy do
          description "Remove network information"
          # params :id required
          control do
            Models::Network.lock!
            nw = find_by_uuid(:Network, params[:id])
            examine_owner(nw) || raise(OperationNotPermitted)
            nw.destroy
            
            response_to([nw.canonical_uuid])
          end
        end

        operation :reserve, :method =>:put, :member=>true do
          description 'Register reserved IP address to the network'
          # params id, string, required
          # params ipaddr, [String,Array], required
          control do
            Models::IpLease.lock!
            nw = find_by_uuid(:Network, params[:id])
            examine_owner(nw) || raise(OperationNotPermitted)

            (ipaddr.is_a?(Array) ? params[:ipaddr] : Array(params[:ipaddr])).each { |ip|
              nw.add_reserved(ip)
            }
            response_to({})
          end
        end

        operation :release, :method =>:put, :member=>true do
          description 'Unregister reserved IP address from the network'
          # params id, string, required
          # params ipaddr, [String,Array], required
          control do
            Models::IpLease.lock!
            nw = find_by_uuid(:Network, params[:id])
            examine_owner(nw) || raise(OperationNotPermitted)

            (ipaddr.is_a?(Array) ? params[:ipaddr] : Array(params[:ipaddr])).each { |ip|
              nw.delete_reserved(ip)
            }
            response_to({})
          end
        end

        operation :add_pool, :method=>:put, :member=>true do
          description 'Label network pool name'
           # param :name required
          control do
            Models::Tag.lock!
            nw = find_by_uuid(:Network, params[:id])
            examine_owner(nw) || raise(OperationNotPermitted)
            nw.label_tag(:NetworkPool, params[:name], @account.canonical_uuid)
            response_to({})
          end
        end
        
        operation :del_pool, :method=>:put, :member=>true do
          description 'Unlabel network pool name'
          # param :name required
          control do
            Models::Tag.lock!
            nw = find_by_uuid(:Network, params[:id])
            examine_owner(nw) || raise(OperationNotPermitted)
            
            nw.unlabel_tag(:NetworkPool, params[:name], @account.canonical_uuid)
            response_to({})
          end
        end
        
        operation :get_pool, :method=>:get, :member=>true do
          description 'List network pool name'
          # param :name required
          control do
            Models::Tag.lock!
             nw = find_by_uuid(:Network, params[:id])
             examine_owner(nw) || raise(OperationNotPermitted)

             res = nw.tags_dataset.filter(:type_id=>Tags.type_id(:NetworkPool)).all.map{|i| i.to_api_document }
             response_to(res)
           end
         end
      end

      collection :instance_specs do
        operation :index do
          description 'Show list of instance template'
          # params start, fixnum, optional 
          # params limit, fixnum, optional
          control do
            res = select_index(:InstanceSpec, {:start => params[:start],
                                 :limit => params[:limit]})
            response_to(res)
          end
        end
      end
      
    end
  end
end
