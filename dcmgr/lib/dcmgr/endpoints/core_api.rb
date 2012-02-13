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

      # Endpoint to handle VM instance.
      namespace '/instances' do
        get do
          # description 'Show list of instances'
          # params start, fixnum, optional 
          # params limit, fixnum, optional
            res = select_index(:Instance, {:start => params[:start],
                                 :limit => params[:limit]})
            response_to(res)
        end

        post do
          # description 'Runs a new VM instance'
          # param :image_id, string, :required
          # param :instance_spec_id, string, :required
          # param :host_node_id, string, :optional
          # param :hostname, string, :optional
          # param :user_data, string, :optional
          # param :security_groups, array, :optional
          # param :ssh_key_id, string, :optional
          # param :network_id, string, :optional
          # param :ha_enabled, string, :optional
            M::Instance.lock!

            wmi = M::Image[params[:image_id]] || raise(E::InvalidImageID)
            spec = M::InstanceSpec[params[:instance_spec_id]] || raise(E::InvalidInstanceSpec)

            if !M::HostNode.check_domain_capacity?(spec.cpu_cores, spec.memory_size)
              raise E::OutOfHostCapacity
            end
            
            # TODO:
            #  "host_id" and "host_pool_id" will be obsolete.
            #  They are used in lib/dcmgr/scheduler/host_node/specify_node.rb.
            if params[:host_id] || params[:host_pool_id] || params[:host_node_id]
              host_node_id = params[:host_id] || params[:host_pool_id] || params[:host_node_id]
              host_node = M::HostNode[host_node_id]
              raise E::UnknownHostNode, "#{host_node_id}" if host_node.nil?
              raise E::InvalidHostNodeID, "#{host_node_id}" if host_node.status != 'online'
            end

            # params is a Mash object. so coverts to raw Hash object.
            instance = M::Instance.entry_new(@account, wmi, spec, params.to_hash) do |i|
              # Set common parameters from user's request.
              i.user_data = params[:user_data] || ''
              # set only when not nil as the table column has not null
              # condition.
              if params[:hostname]
                if M::Instance::ValidationMethods.hostname_uniqueness(@account.canonical_uuid,
                                                                           params[:hostname])
                  i.hostname = params[:hostname]
                else
                  raise E::DuplicateHostname
                end
              end

              if params[:ssh_key_id]
                ssh_key_pair = M::SshKeyPair[params[:ssh_key_id]]

                if ssh_key_pair.nil?
                  raise E::UnknownSshKeyPair, "#{params[:ssh_key_id]}"
                else
                  i.set_ssh_key_pair(ssh_key_pair)
                end
              end

              if params[:ha_enabled] == 'true'
                i.ha_enabled = 1
              end
            end
            instance.save

            if params[:nf_group].is_a?(Array) || params[:nf_group].is_a?(String)
              instance.join_security_group(params[:nf_group])
            elsif params[:security_groups].is_a?(Array) || params[:security_groups].is_a?(String)
              instance.join_security_group(params[:security_groups])
            end
            
            instance.state = :scheduling
            instance.save

            case wmi.boot_dev_type
            when M::Image::BOOT_DEV_SAN
              # create new volume from snapshot.
              snapshot_id = wmi.source[:snapshot_id]
              vs = find_volume_snapshot(snapshot_id)

              if !M::StorageNode.check_domain_capacity?(vs.size)
                raise E::OutOfDiskSpace
              end
              
              vol = M::Volume.entry_new(@account, vs.size, params.to_hash) do |v|
                if vs
                  v.snapshot_id = vs.canonical_uuid
                end
                v.boot_dev = 1
              end
              # assign instance -> volume
              vol.instance = instance
              vol.state = :scheduling
              vol.save

            when M::Image::BOOT_DEV_LOCAL
            else
              raise "Unknown boot type"
            end

            commit_transaction
            Dcmgr.messaging.submit("scheduler",
                                   'schedule_instance', instance.canonical_uuid)

            # retrieve latest instance data.
            # if not, security_groups value is empty.
            instance = find_by_uuid(:Instance, instance.canonical_uuid)

            response_to(instance.to_api_document)
        end

        get '/:id' do
          #param :account_id, :string, :optional
            i = find_by_uuid(:Instance, params[:id])
            raise E::UnknownInstance if i.nil?

            response_to(i.to_api_document)
        end

        delete '/:id' do
          # description 'Shutdown the instance'
            i = find_by_uuid(:Instance, params[:id])
            if examine_owner(i)
            else
              raise E::OperationNotPermitted
            end

            case i.state
            when 'stopped'
              # just destroy the record.
              i.destroy
            when 'terminated', 'scheduling'
              raise E::InvalidInstanceState, i.state
            else
              res = Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'terminate', i.canonical_uuid)
            end
            response_to([i.canonical_uuid])
        end

        put '/:id/reboot' do
          # description 'Reboots the instance'
            i = find_by_uuid(:Instance, params[:id])
            raise E::InvalidInstanceState, i.state if i.state != 'running'
            Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'reboot', i.canonical_uuid)
            response_to({})
        end

        put '/:id/stop' do
          # description 'Stop the instance'
            i = find_by_uuid(:Instance, params[:id])
            raise E::InvalidInstanceState, i.state if i.state != 'running'

            # relase IpLease from nic.
            i.nic.each { |nic|
              nic.release_ip_lease
            }
            
            Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'stop', i.canonical_uuid)
            response_to([i.canonical_uuid])
        end

        put '/:id/start' do
          # description 'Restart the instance'
            instance = find_by_uuid(:Instance, params[:id])
            raise E::InvalidInstanceState, instance.state if instance.state != 'stopped'
            instance.state = :scheduling
            instance.save

            commit_transaction
            Dcmgr.messaging.submit("scheduler", 'schedule_start_instance', instance.canonical_uuid)
            response_to([instance.canonical_uuid])
        end

      end

      namespace '/images' do
        post do
          # description 'Register new machine image'
            M::Image.lock!
            raise NotImplementedError
        end

        get do
          # description 'Show list of machine images'
            res = select_index(:Image, {:start => params[:start],
                                 :limit => params[:limit]})
            response_to(res)
        end

        get '/:id' do
          # description "Show a machine image details."
            i = find_by_uuid(:Image, params[:id])
            if !(examine_owner(i) || i.is_public)
              raise E::OperationNotPermitted
            end
            response_to(i.to_api_document(@account.canonical_uuid))
        end

        delete '/:id' do
          # description 'Delete a machine image'
            M::Image.lock!
            i = find_by_uuid(:Image, params[:id])
            if examine_owner(i)
              i.destroy
            else
              raise E::OperationNotPermitted
            end
            response_to([i.canonical_uuid])
        end
      end

      # obsolute path: "/host_pools"
      [ '/host_pools', '/host_nodes' ].each do |path|
        namespace path do
          get do
            # description 'Show list of host pools'
              res = select_index(:HostNode, {:start => params[:start],
                                   :limit => params[:limit]})
              response_to(res)
          end

          get '/:id' do
            # description 'Show status of the host'
            #param :account_id, :string, :optional
              hp = find_by_uuid(:HostNode, params[:id])
              raise E::OperationNotPermitted unless examine_owner(hp)

              response_to(hp.to_api_document)
          end
        end
      end

      namespace '/volumes' do
        get do
          # description 'Show lists of the volume'
          # params start, fixnum, optional
          # params limit, fixnum, optional
            res = select_index(:Volume, {:start => params[:start],
                                 :limit => params[:limit]})
            response_to(res)
        end

        get '/:id' do
          # description 'Show the volume status'
          # params id, string, required
            volume_id = params[:id]
            raise E::UndefinedVolumeID if volume_id.nil?
            v = find_by_uuid(:Volume, volume_id)
            response_to(v.to_api_document)
        end

        post do
          # description 'Create the new volume'
          # params volume_size, string, required
          # params snapshot_id, string, optional
          # params storage_pool_id, string, optional
            M::Volume.lock!
            sp = vs = vol = nil
            # input parameter validation
            if params[:snapshot_id]
              vs = find_volume_snapshot(params[:snapshot_id])
            elsif params[:volume_size]
              if !(Dcmgr.conf.create_volume_max_size.to_i >= params[:volume_size].to_i) ||
                  !(params[:volume_size].to_i >= Dcmgr.conf.create_volume_min_size.to_i)
                raise E::InvalidVolumeSize
              end
              if params[:storage_pool_id]
                sp = find_by_uuid(:StorageNode, params[:storage_pool_id])
                raise E::UnknownStorageNode if sp.nil?
                raise E::StorageNodeNotPermitted if sp.account_id != @account.canonical_uuid
              end
            else
              raise E::UndefinedRequiredParameter
            end

            volume_size = (vs ? vs.size : params[:volume_size].to_i)

            if !M::StorageNode.check_domain_capacity?(volume_size)
              raise E::OutOfDiskSpace
            end

            # params is a Mash object. so coverts to raw Hash object.
            vol = M::Volume.entry_new(@account, volume_size, params.to_hash) do |v|
              if vs
                v.snapshot_id = vs.canonical_uuid
              end
            end
            vol.save

            if sp.nil?
              # going to storage node scheduling mode.
              vol.state = :scheduling
              vol.save

              commit_transaction

              Dcmgr.messaging.submit("scheduler", 'schedule_volume', vol.canonical_uuid)
            else
              begin
                vol.storage_node = sp
                vol.save
              rescue M::Volume::CapacityError => e
                logger.error(e)
                raise E::OutOfDiskSpace
              end

              vol.state = :pending
              vol.save

              commit_transaction

              repository_address = nil
              if vol.snapshot
                repository_address = Dcmgr::StorageService.repository_address(vol.snapshot.destination_key)
              end

              res = Dcmgr.messaging.submit("sta-handle.#{vol.storage_node.node_id}", 'create_volume', vol.canonical_uuid, repository_address)
            end

            response_to(vol.to_api_document)
        end

        delete '/:id' do
          # description 'Delete the volume'
          # params id, string, required
            volume_id = params[:id]
            raise E::UndefinedVolumeID if volume_id.nil?

            vol = find_by_uuid(:Volume, volume_id)
            raise E::UnknownVolume if vol.nil?
            raise E::InvalidVolumeState, "#{vol.state}" unless vol.state == "available"


            begin
              v  = M::Volume.delete_volume(@account.canonical_uuid, volume_id)
            rescue M::Volume::RequestError => e
              logger.error(e)
              raise E::InvalidDeleteRequest
            end
            raise E::UnknownVolume if v.nil?

            commit_transaction
            res = Dcmgr.messaging.submit("sta-handle.#{v.storage_node.node_id}", 'delete_volume', v.canonical_uuid)
            response_to([v.canonical_uuid])
        end

        put '/:id/attach' do
          # description 'Attachd the volume'
          # params id, string, required
          # params instance_id, string, required
            raise E::UndefinedInstanceID if params[:instance_id].nil?
            raise E::UndefinedVolumeID if params[:id].nil?

            i = find_by_uuid(:Instance, params[:instance_id])
            raise E::UnknownInstance if i.nil?
            raise E::InvalidInstanceState unless i.live? && i.state == 'running'

            v = find_by_uuid(:Volume, params[:id])
            raise E::UnknownVolume if v.nil?
            raise E::AttachVolumeFailure, "Volume is attached to running instance." if v.instance

            v.instance = i
            v.save
            commit_transaction
            res = Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'attach', i.canonical_uuid, v.canonical_uuid)

            response_to(v.to_api_document)
        end

        get '/:id/detach' do
          # description 'Detachd the volume'
          # params id, string, required
            raise E::UndefinedVolumeID if params[:id].nil?

            v = find_by_uuid(:Volume, params[:id])
            raise E::UnknownVolume if v.nil?
            raise E::DetachVolumeFailure, "Volume is not attached to any instance." if v.instance.nil?
            # the volume as the boot device can not be detached.
            raise E::DetachVolumeFailure, "boot device can not be detached" if v.boot_dev == 1
            i = v.instance
            raise E::InvalidInstanceState unless i.live? && i.state == 'running'
            commit_transaction
            res = Dcmgr.messaging.submit("hva-handle.#{i.host_node.node_id}", 'detach', i.canonical_uuid, v.canonical_uuid)
            response_to(v.to_api_document)
        end

      end


      namespace '/volume_snapshots' do
        get do
          # description 'Show lists of the volume_snapshots'
          # params start, fixnum, optional
          # params limit, fixnum, optional
            res = select_index(:VolumeSnapshot, {:start => params[:start],
                                 :limit => params[:limit]})
            response_to(res)
        end

      get '/upload_destination' do
        c = Dcmgr::StorageService::snapshot_repository_config.dup
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

        get '/:id' do
          # description 'Show the volume status'
          # params id, string, required
            snapshot_id = params[:id]
            raise E::UndefinedVolumeSnapshotID if snapshot_id.nil?
            vs = find_by_uuid(:VolumeSnapshot, snapshot_id)
            response_to(vs.to_api_document)
        end

        post do
          # description 'Create a new volume snapshot'
          # params volume_id, string, required
          # params detination, string, required
          # params storage_pool_id, string, optional
            M::Volume.lock!
            raise E::UndefinedVolumeID if params[:volume_id].nil?

            v = find_by_uuid(:Volume, params[:volume_id])
            raise E::UnknownVolume if v.nil?
            raise E::InvalidVolumeState unless v.ready_to_take_snapshot?
            vs = v.create_snapshot(@account.canonical_uuid)
            sp = vs.storage_node
            destination_key = Dcmgr::StorageService.destination_key(@account.canonical_uuid, params[:destination], sp.snapshot_base_path, vs.snapshot_filename)
            vs.update_destination_key(@account.canonical_uuid, destination_key)
            commit_transaction

            repository_address = Dcmgr::StorageService.repository_address(destination_key)
            res = Dcmgr.messaging.submit("sta-handle.#{sp.node_id}", 'create_snapshot', vs.canonical_uuid, repository_address)
            response_to(vs.to_api_document)
        end

        delete '/:id' do
          # description 'Delete the volume snapshot'
          # params id, string, required
            M::VolumeSnapshot.lock!
            snapshot_id = params[:id]
            raise E::UndefindVolumeSnapshotID if snapshot_id.nil?

            v = find_by_uuid(:VolumeSnapshot, snapshot_id)
            raise E::UnknownVolumeSnapshot if v.nil?
            raise E::InvalidVolumeState unless v.state == "available"

            destination_key = v.destination_key

            begin
              vs  = M::VolumeSnapshot.delete_snapshot(@account.canonical_uuid, snapshot_id)
            rescue M::VolumeSnapshot::RequestError => e
              logger.error(e)
              raise E::InvalidDeleteRequest
            end
            raise E::UnknownVolumeSnapshot if vs.nil?
            sp = vs.storage_node

            commit_transaction

            repository_address = Dcmgr::StorageService.repository_address(destination_key)
            res = Dcmgr.messaging.submit("sta-handle.#{sp.node_id}", 'delete_snapshot', vs.canonical_uuid, repository_address)
            response_to([vs.canonical_uuid])
        end

      end

      namespace '/security_groups' do
        # description 'Show lists of the security groups'
        get do
            res = select_index(:SecurityGroup, {:start => params[:start],
                                 :limit => params[:limit]})
            response_to(res)
        end

        get '/:id' do
          # description 'Show the security group'
            g = find_by_uuid(:SecurityGroup, params[:id])
            raise E::OperationNotPermitted unless examine_owner(g)

            response_to(g.to_api_document)
        end

        post do
          # description 'Register a new security group'
          # params description, string
          # params rule, string
            M::SecurityGroup.lock!
            begin
              g = M::SecurityGroup.create(:account_id=>@account.canonical_uuid,
                                               :description=>params[:description],
                                               :rule=>params[:rule])
            rescue M::InvalidSecurityGroupRuleSyntax => e
              raise E::InvalidSecurityGroupRule, e.message
            end
            
            response_to(g.to_api_document)
        end

        put '/:id' do
          # description "Update parameters for the security group"
          # params description, string
          # params rule, string
            g = find_by_uuid(:SecurityGroup, params[:id])

            raise E::UnknownSecurityGroup if g.nil?
            raise E::OperationNotPermitted unless examine_owner(g)

            if params[:description]
              g.description = params[:description]
            end
            if params[:rule]
              g.rule = params[:rule]
            end

            begin
              g.save
            rescue M::InvalidSecurityGroupRuleSyntax => e
              raise E::InvalidSecurityGroupRule, e.message
            end

            commit_transaction
            # refresh security group rules on host nodes.
            Dcmgr.messaging.event_publish('hva/security_group_updated', :args=>[g.canonical_uuid])

            response_to(g.to_api_document)
        end

        delete '/:id' do
          # description "Delete the security group"
            M::SecurityGroup.lock!
            g = find_by_uuid(:SecurityGroup, params[:id])

            raise E::UnknownSecurityGroup if g.nil?
            raise E::OperationNotPermitted unless examine_owner(g)

            # raise E::OperationNotPermitted if g.instances.size > 0
            begin
              g.destroy
            rescue => e
              # logger.error(e)
              raise E::OperationNotPermitted
            end

            response_to([g.canonical_uuid])
        end

      end

      # obsolute path: "/storage_pools"
      [ '/storage_pools', '/storage_nodes' ].each do |path|
        namespace path do
          get do
            # description 'Show lists of the storage_pools'
            # params start, fixnum, optional
            # params limit, fixnum, optional
              res = select_index(:StorageNode, {:start => params[:start],
                                   :limit => params[:limit]})
              response_to(res)
          end

          get '/:id' do
            # description 'Show the storage_pool status'
            # params id, string, required
              pool_id = params[:id]
              raise E::UndefinedStorageNodeID if pool_id.nil?
              vs = find_by_uuid(:StorageNode, pool_id)
              raise E::UnknownStorageNode if vs.nil?
              response_to(vs.to_api_document)
          end
        end
      end

      namespace '/ssh_key_pairs' do
        # description "List ssh key pairs in account"
        get do
          # params start, fixnum, optional
          # params limit, fixnum, optional
            res = select_index(:SshKeyPair, {:start => params[:start],
                                 :limit => params[:limit]})
            response_to(res)
        end

        get '/:id' do
          # description "Retrieve details about ssh key pair"
          # params :id required
          # params :format optional [openssh,putty]
            ssh = find_by_uuid(:SshKeyPair, params[:id])

            response_to(ssh.to_api_document)
        end

        post do
          # description "Create ssh key pair information"
          # params :download_once optional set true if you do not want
          #        to save private key info on database.
            M::SshKeyPair.lock!
            keydata = nil

            ssh = M::SshKeyPair.entry_new(@account) do |s|
              keydata = M::SshKeyPair.generate_key_pair(s.uuid)
              s.public_key = keydata[:public_key]
              s.finger_print = keydata[:finger_print]

              if params[:download_once] != 'true'
                s.private_key = keydata[:private_key]
              end

              if params[:description]
                s.description = params[:description]
              end
            end

            begin
              ssh.save
            rescue => e
              raise E::DatabaseError, e.message
            end

            # include private_key data in response even if
            # it's not going to be stored on DB.
            response_to(ssh.to_api_document.merge(:private_key=>keydata[:private_key]))
        end

        delete '/:id' do
          # description "Remove ssh key pair information"
          # params :id required
            M::SshKeyPair.lock!
            ssh = find_by_uuid(:SshKeyPair, params[:id])
            if examine_owner(ssh)
              ssh.destroy
            else
              raise E::OperationNotPermitted
            end

            response_to([ssh.canonical_uuid])
        end

        put '/:id' do
          # description "Update ssh key pair information"
            M::SshKeyPair.lock!
            ssh = find_by_uuid(:SshKeyPair, params[:id])
            if examine_owner(ssh)
              ssh.description = params[:description]
              ssh.save_changes
            else
              raise E::OperationNotPermitted
            end

            response_to([ssh.canonical_uuid])
        end
      end

      namespace '/networks' do
        # description "Networks for account"
        get do
          # description "List networks in account"
          # params start, fixnum, optional
          # params limit, fixnum, optional
            res = select_index(:Network, {:start => params[:start],
                                 :limit => params[:limit]})
            response_to(res)
        end

        get '/:id' do
          # description "Retrieve details about a network"
          # params :id required
            nw = find_by_uuid(:Network, params[:id])
            examine_owner(nw) || raise(E::OperationNotPermitted)

            response_to(nw.to_api_document)
        end

        post do
          # description "Create new network"
          # params :gw required default gateway address of the network
          # params :network required network address of the network
          # params :prefix optional  netmask bit length. it will be
          #               set 24 if none.
          # params :description optional description for the network
            M::Network.lock!
            savedata = {
              :account_id=>@account.canonical_uuid,
              :ipv4_gw => params[:gw],
              :ipv4_network => params[:network],
              :prefix => params[:prefix].to_i,
              :description => params[:description],
            }
            nw = M::Network.create(savedata)

            response_to(nw.to_api_document)
        end

        delete '/:id' do
          # description "Remove network information"
          # params :id required
            M::Network.lock!
            nw = find_by_uuid(:Network, params[:id])
            examine_owner(nw) || raise(E::OperationNotPermitted)
            nw.destroy

            response_to([nw.canonical_uuid])
        end

        put '/:id/reserve' do
          # description 'Register reserved IP address to the network'
          # params id, string, required
          # params ipaddr, [String,Array], required
            M::IpLease.lock!
            nw = find_by_uuid(:Network, params[:id])
            examine_owner(nw) || raise(E::OperationNotPermitted)

            (params[:ipaddr].is_a?(Array) ? params[:ipaddr] : Array(params[:ipaddr])).each { |ip|
              nw.ip_lease_dataset.add_reserved(ip)
            }
            response_to({})
        end

        put '/:id/release' do
          # description 'Unregister reserved IP address from the network'
          # params id, string, required
          # params ipaddr, [String,Array], required
            M::IpLease.lock!
            nw = find_by_uuid(:Network, params[:id])
            examine_owner(nw) || raise(E::OperationNotPermitted)

            (params[:ipaddr].is_a?(Array) ? params[:ipaddr] : Array(params[:ipaddr])).each { |ip|
              nw.ip_lease_dataset.delete_reserved(ip)
            }
            response_to({})
        end

        put '/:id/add_pool' do
          # description 'Label network pool name'
          # param :name required
            M::Tag.lock!
            nw = find_by_uuid(:Network, params[:id])
            examine_owner(nw) || raise(E::OperationNotPermitted)

            nw.label_tag(:NetworkPool, params[:name], @account.canonical_uuid)
            response_to({})
        end

        put '/:id/del_pool' do
          description 'Unlabel network pool name'
          # param :name required
          control do
            M::Tag.lock!
            nw = find_by_uuid(:Network, params[:id])
            examine_owner(nw) || raise(E::OperationNotPermitted)

            nw.unlabel_tag(:NetworkPool, params[:name], @account.canonical_uuid)
            response_to({})
          end
        end

        put '/:id/get_pool' do
          description 'List network pool name'
          # param :name required
          control do
            M::Tag.lock!
            nw = find_by_uuid(:Network, params[:id])
            examine_owner(nw) || raise(E::OperationNotPermitted)

            res = nw.tags_dataset.filter(:type_id=>Tags.type_id(:NetworkPool)).all.map{|i| i.to_api_document }
            response_to(res)
           end
         end

        # Temporary names as the current code is incapable of having
        # multiple names with different operations.
        get '/:id/get_port' do
          # description 'List ports on this network'
          # params start, fixnum, optional
          # params limit, fixnum, optional
            M::NetworkPort.lock!
            nw = find_by_uuid(:Network, params[:id])
            examine_owner(nw) || raise(E::OperationNotPermitted)

            result = []
            nw.network_port.each { |port|
              result << port.to_api_document.merge(:network_id => nw.canonical_uuid)
            }

            response_to(result)
         end

        put '/:id/add_port' do
          # description 'Create a port on this network'
            M::NetworkPort.lock!
            nw = find_by_uuid(:Network, params[:id])
            examine_owner(nw) || raise(E::OperationNotPermitted)

            savedata = {
              :network_id => nw.id
            }
            port = M::NetworkPort.create(savedata)

            response_to(port.to_api_document.merge(:network_id => nw.canonical_uuid))
        end

        put '/:id/del_port' do
          # description 'Create a port on this network'
          # param :port_id required
            M::NetworkPort.lock!
            nw = find_by_uuid(:Network, params[:id])
            examine_owner(nw) || raise(E::OperationNotPermitted)

            port = nw.network_port.detect { |itr| itr.canonical_uuid == params[:port_id] }
            raise(E::UnknownNetworkPort) if port.nil?

            port.destroy
            response_to({})
        end

      end

      # Should be under '/networks/{network-id}/ports', however due to
      # lack of namespaces we put the create and index calls in the
      # root namespace.
      namespace '/ports' do
        # description "Ports on a network"

        get '/:id' do
          # description "Retrieve details about a port"
          # params :id required
            port = find_by_uuid(:NetworkPort, params[:id])

            # Find a better way to convert to canonical network uuid.
            nw = find_by_uuid(:Network, port[:network_id])

            response_to(port.to_api_document.merge(:network_id => nw.canonical_uuid))
        end
        
        # delete '/:id' do
        #   # description "Remove a port"
        #   # params :id required
        #     response_to({})
        # end

        put '/:id/attach' do
          # description 'Attach a vif to this port'
          # params :id required
          # params :attachment_id required
            result = []

            M::NetworkPort.lock!
            port = find_by_uuid(:NetworkPort, params[:id])
            raise(E::NetworkPortAlreadyAttached) unless port.instance_nic.nil?

            nic = find_by_uuid(:InstanceNic, params[:attachment_id])
            raise(E::NetworkPortNicNotFound) if nic.nil?

            nw = find_by_uuid(:Network, port[:network_id])
            examine_owner(nw) || raise(E::OperationNotPermitted)

            # Verify that the vif belongs to network?

            port.instance_nic = nic
            port.save_changes
            response_to({})
        end

        put '/:id/detach' do
          # description 'Detach a vif from this port'
          # param :port_id required
            # M::NetworkPort.lock!
            # nw = find_by_uuid(:Network, params[:id])
            # examine_owner(nw) || raise(E::OperationNotPermitted)

            # port = nw.network_port.detect { |itr| itr.canonical_uuid == params[:port_id] }
            # raise(E::UnknownNetworkPort) if port.nil?

            # port.destroy
            response_to({})
        end
      end
      
      namespace '/instance_specs' do
        get do
          # description 'Show list of instance template'
          # params start, fixnum, optional
          # params limit, fixnum, optional
            res = select_index(:InstanceSpec, {:start => params[:start],
                                 :limit => params[:limit]})
            response_to(res)
        end

        get '/:id' do
          # description "Show the instance template"
          # params :id required
            inst_spec = find_by_uuid(:InstanceSpec, params[:id])
            response_to(inst_spec.to_api_document)
        end
      end
  end
end
