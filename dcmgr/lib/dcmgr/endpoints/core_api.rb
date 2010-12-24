# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'sinatra/rabbit'
require 'sinatra/sequel_transaction'

require 'json'
require 'extlib/hash'

require 'dcmgr/endpoints/errors'

module Dcmgr
  module Endpoints
    class CoreAPI < Sinatra::Base
      include Dcmgr::Logger
      register Sinatra::Rabbit
      register Sinatra::SequelTransaction

      disable :sessions
      disable :show_exceptions

      before do
        request.env['dcmgr.frotend_system.id'] = 1
        request.env['HTTP_X_VDC_REQUESTER_TOKEN']='u-xxxxxx'
        request.env['HTTP_X_VDC_ACCOUNT_UUID']='a-00000000'
      end

      before do
        @params = parsed_request_body if request.post?
        @account = Models::Account[request.env['HTTP_X_VDC_ACCOUNT_UUID']]
        @requester_token = request.env['HTTP_X_VDC_REQUESTER_TOKEN']
        #@frontend = Models::FrontendSystem[request.env['dcmgr.frotend_system.id']]

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
        end
        return hash.values.first
      end

      def response_to(res)
        mime = @mime_types.first unless @mime_types.nil?
        case mime.to_s
        when 'application/yaml', 'text/yaml'
          content_type 'yaml'
          res.to_yaml
        when 'application/xml', 'text/xml'
          raise NotImplementedError
        else
          content_type 'json'
          res.to_json
        end
      end

      # I am not going to use error(ex, &blk) hook since it works only
      # when matches the Exception class exactly. I expect to match
      # whole subclasses of APIError so that override handle_exception!().
      def handle_exception!(boom)
        logger.error(boom)
        if boom.kind_of?(APIError)
          @env['sinatra.error'] = boom
          error(boom.status_code, boom.class.to_s)
        else
          super
        end
      end

      def create_volume_from_snapshot(account_id, snapshot_id)
        vs = find_by_uuid(:VolumeSnapshot, snapshot_id)
        raise UnknownVolumeSnapshot if vs.nil?
        raise InvalidRequestCredentials unless vs.state.to_s == 'available'
        vs.create_volume(account_id)
      end
        
      def examine_owner(account_resource)
        if @account.canonical_uuid == account_resource.account_id ||
            @account.canonical_uuid == 'a-00000000'
          return true
        else
          return false
        end
      end

      collection :accounts do
        operation :index do
          control do
          end
        end

        operation :show do
          control do
            a = find_account(params[:id])
            response_to(a.to_hash)
          end
        end

        operation :create do
          description 'Register a new account'
          control do
            a = Models::Account.create()
            response_to(a.to_hash)
          end
        end

        operation :destroy do
          description 'Unregister the account.'
          # Associated resources all have to be destroied prior to
          # removing the account.
          #param :id, :string, :required
          control do
            a = find_account(params[:id])
            a.destroy

            response_to([a.canonical_uuid])
          end
        end

        operation :enable, :method=>:get, :member=>true do
          description 'Enable the account for all operations'
          control do
            a = find_account(params[:id])
            a.enabled = Models::Account::ENABLED
            a.save

            respond_to { |f|
              f.json { {} }
            }
          end
        end

        operation :disable, :method=>:get, :member=>true do
          description 'Disable the account for all operations'
          control do
            a = find_account(params[:id])
            a.enabled = Models::Account::DISABLED
            a.save

            respond_to { |f|
              f.json { {} }
            }
          end
        end

        operation :add_tag, :method=>:get, :member=>true do
          description 'Add a tag belongs to the account'
          #param :tag_name, :string, :required
          control do
            a = find_account(params[:id])

            tag_class = Models::Tags.find_tag_class(params[:tag_name])
            raise "UnknownTagClass: #{params[:tag_name]}" if tag_class.nil?

            a.add_tag(tag_class.new(:name=>params[:name]))
          end
        end

        operation :remove_tag, :method=>:get, :member=>true do
          description 'Unlink the associated tag of the account'
          #param :tag_id, :string, :required
          control do
            a = find_account(params[:id])
            t = a.tags_dataset.filter(:uuid=>params[:tag_id]).first
            if t
              a.remove_tag(t)
            else
              raise "Unknown or disassociated tag for #{a.cuuid}: #{params[:tag_id]}"
            end
          end
        end
      end

      collection :tags do
        operation :create do
          description 'Register new tag to the account'
          #param :tag_name, :string, :required
          #param :type_id, :fixnum, :optional
          #param :account_id, :string, :optional
          control do
            tag_class = Models::Tag.find_tag_class(params[:tag_name])

            tag_class.create

          end
        end

        operation :show do
          #param :account_id, :string, :optional
          control do
          end
        end

        operation :destroy do
          description 'Create a new user'
          control do
          end
        end

        operation :update do
          control do
          end
        end
      end

      # Endpoint to handle VM instance.
      collection :instances do
        operation :index do
          description 'Show list of instances'
          # params start, fixnum, optional 
          # params limit, fixnum, optional
          control do
            start = params[:start].to_i
            start = start < 1 ? 0 : start
            limit = params[:limit].to_i
            limit = limit < 1 ? nil : limit
            
            total_ds = Models::Instance.where(:account_id=>@account.canonical_uuid)
            partial_ds  = total_ds.dup.order(:id)
            partial_ds = partial_ds.limit(limit, start) if limit.is_a?(Integer)

            res = [{
              :owner_total => total_ds.count,
              :start => start,
              :limit => limit,
              :results=> partial_ds.all.map {|i| i.to_api_document }
            }]
            
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
            
            wmi = find_by_uuid(:Image, params[:image_id])
            spec = find_by_uuid(:InstanceSpec, (params[:instance_spec_id] || 'is-kpf0pasc'))

            # look up params[:host_id] in following order:
            # 1. assume the host pool name.
            # 2. assume hp-xxxxx or tag-xxxxx style uuid
            # 3. assign default shared host pool.
            params[:host_id] ||= params[:host_pool_id]
            hostnode = pool = nil
            if params[:host_id]
              # TODO: smart way to preload model libs.
              Models::HostPool; Tags::HostPool;
              if pool = Tags::HostPool.find(:account_id=>@account.canonical_uuid,
                                            :name=>params[:host_id])
                # Pattern 1st
              elsif hostnode = Models::Taggable.find(params[:host_id])
                # Pattern 2nd
                case hostnode
                when Models::HostPool
                when Tags::HostPool
                  hostnode = hostnode.pick(spec)
                else
                  raise UnknownHostPool, "Could not find the host: #{params[:host_id]}"
                end
              end
            else
              # Pattern 3rd
              pool = Tags::HostPool[Dcmgr.conf.default_shared_host_pool]
              hostnode = pool.pick(spec)
            end
            raise UnknownHostPool, "Could not find host pool: #{params[:host_id]}" if hostnode.nil?
            raise OutOfHostCapacity unless hostnode.check_capacity(spec)

            # look up params[:network_id] in following order:
            # 1. assume the network pool name.
            # 2. assume nw-xxxxx or tag-xxxxx style uuid
            # 3. assign default shared network pool.
            # then randomly choose one network from the pool object.
            network = pool = nil
            if params[:network_id]
              # TODO: smart way to preload model libs.
              Models::Network; Tags::NetworkPool;
              if pool = Tags::NetworkPool.find(:account_id=>@account.canonical_uuid,
                                               :name=>params[:network_id])
                # Pattern 1st
                network = pool.pick
              elsif network = Models::Taggable.find(params[:network_id])
                # Pattern 2nd
                case network
                when Models::Network
                when Tags::NetworkPool
                  network = network.pick
                else
                  raise "Unknown network uuid: #{params[:network_id]}"
                end
              end
            else
              # Pattern 3rd
              pool = Tags::NetworkPool[Dcmgr.conf.default_shared_network_pool]
              network = pool.pick
            end
            raise "Can not find the network" if network.nil?
            raise "Out of IP addresses in the network" unless network.available_ip_nums > 0

            inst = hostnode.create_instance(@account, wmi, spec, network) do |i|
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
                  i.ssh_key_pair_id = ssh_key_pair.canonical_uuid
                end
              end

              if params[:ha_enabled] == 'true'
                i.ha_enabled = 1
              end
            end

            unless params[:nf_group].is_a?(Array)
              params[:nf_group] = ['default']
            end
            inst.join_nfgroup_by_name(@account.canonical_uuid, params[:nf_group])

            case wmi.boot_dev_type
            when Models::Image::BOOT_DEV_SAN
              # create new volume from snapshot.
              snapshot_id = wmi.source[:snapshot_id]
              vol = create_volume_from_snapshot(@account.canonical_uuid, snapshot_id)

              vol.boot_dev = 1
              vol.instance = inst
              vol.save
              res = Dcmgr.messaging.submit("kvm-handle.#{hostnode.node_id}", 'run_vol_store', inst.canonical_uuid, vol.canonical_uuid)
            when Models::Image::BOOT_DEV_LOCAL
              res = Dcmgr.messaging.submit("kvm-handle.#{hostnode.node_id}", 'run_local_store', inst.canonical_uuid)
            else
              raise "Unknown boot type"
            end
            
            response_to(inst.to_api_document)
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
            Models::Instance.lock!
            i = find_by_uuid(:Instance, params[:id])
            if examine_owner(i)
            else
              raise OperationNotPermitted
            end
            res = Dcmgr.messaging.submit("kvm-handle.#{i.host_pool.node_id}", 'terminate', i.canonical_uuid)
            response_to([i.canonical_uuid])
          end
        end

        operation :reboot, :method=>:put, :member=>true do
          description 'Reboots the instance'
          control do
            Models::Instance.lock!
            i = find_by_uuid(:Instance, params[:id])
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
            start = params[:start].to_i
            start = start < 1 ? 0 : start
            limit = params[:limit].to_i
            limit = limit < 1 ? nil : limit
            
            total_ds = Models::Image.where(:account_id=>@account.canonical_uuid)
            partial_ds  = total_ds.dup.order(:id)
            partial_ds = partial_ds.limit(limit, start) if limit.is_a?(Integer)

            res = [{
              :owner_total => total_ds.count,
              :start => start,
              :limit => limit,
              :results=> partial_ds.all.map {|i| i.to_hash }
            }]
            
            response_to(res)
          end
        end

        operation :show do
          description "Show a machine image details."
          control do
            i = find_by_uuid(:Image, params[:id])
            # TODO: add visibility by account check
            unless examine_owner(i)
              raise OperationNotPermitted
            end
            response_to(i.to_hash)
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
            start = params[:start].to_i
            start = start < 1 ? 0 : start
            limit = params[:limit].to_i
            limit = limit < 1 ? nil : limit
            
            total_ds = Models::HostPool.where(:account_id=>@account.canonical_uuid)
            partial_ds  = total_ds.dup.order(:id)
            partial_ds = partial_ds.limit(limit, start) if limit.is_a?(Integer)

            res = [{
              :owner_total => total_ds.count,
              :start => start,
              :limit => limit,
              :results=> partial_ds.all.map {|i| i.to_hash }
            }]
            
            response_to(res)
          end
        end

        operation :show do
          description 'Show status of the host'
          #param :account_id, :string, :optional
          control do
            hp = find_by_uuid(:HostPool, params[:id])
            raise OperationNotPermitted unless examine_owner(hp)
            
            response_to(hp.to_hash)
          end
        end
      end

      collection :volumes do
        operation :index do
          description 'Show lists of the volume'
          # params start, fixnum, optional 
          # params limit, fixnum, optional
          control do
            start = params[:start].to_i
            start = start < 1 ? 0 : start
            limit = params[:limit].to_i
            limit = limit < 1 ? nil : limit

            total_v = Models::Volume.where(:account_id => @account.canonical_uuid)
            partial_v = total_v.dup.order(:id)
            partial_v = partial_v.limit(limit, start) if limit.is_a?(Integer)
            res = [{
              :owner_total => total_v.count,
              :start => start,
              :limit => limit,
              :results => partial_v.all.map { |v| v.to_api_document}
            }]
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
            if params[:snapshot_id]
              v = create_volume_from_snapshot(@account.canonical_uuid, params[:snapshot_id])
              sp = v.storage_pool
            elsif params[:volume_size]
              if !(Dcmgr.conf.create_volume_max_size.to_i >= params[:volume_size].to_i) ||
                  !(params[:volume_size].to_i >= Dcmgr.conf.create_volume_min_size.to_i)
                raise InvalidVolumeSize
              end
              if params[:storage_pool_id]
                sp = find_by_uuid(:StoragePool, params[:storage_pool_id])
                raise StoragePoolNotPermitted if sp.account_id != @account.canonical_uuid
              end
              raise UnknownStoragePool if sp.nil?
              begin
                v = sp.create_volume(@account.canonical_uuid, params[:volume_size])
              rescue Models::Volume::DiskError => e
                logger.error(e)
                raise OutOfDiskSpace
              rescue Sequel::DatabaseError => e
                logger.error(e)
                raise DatabaseError
              end
            else
              raise UndefinedRequiredParameter
            end

            res = Dcmgr.messaging.submit("zfs-handle.#{sp.values[:node_id]}", 'create_volume', v.canonical_uuid)
            response_to(v.to_api_document)
          end
        end

        operation :destroy do
          description 'Delete the volume'
          # params id, string, required
          control do
            Models::Volume.lock!
            volume_id = params[:id]
            raise UndefinedVolumeID if volume_id.nil?

            begin
              v  = Models::Volume.delete_volume(@account.canonical_uuid, volume_id)
            rescue Models::Volume::RequestError => e
              logger.error(e)
              raise InvalidDeleteRequest
            end
            raise UnknownVolume if v.nil?
            sp = v.storage_pool

            res = Dcmgr.messaging.submit("zfs-handle.#{sp.values[:node_id]}", 'delete_volume', v.canonical_uuid)
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
            res = Dcmgr.messaging.submit("kvm-handle.#{i.host_pool.node_id}", 'attach', i.canonical_uuid, v.canonical_uuid)

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
            res = Dcmgr.messaging.submit("kvm-handle.#{i.host_pool.node_id}", 'detach', i.canonical_uuid, v.canonical_uuid)
            response_to(v.to_api_document)
          end
        end

        operation :status, :method =>:get, :member =>true do
          description 'Show the status'
          control do
            vl = [{ :id => 1, :uuid => 'vol-xxxxxxx', :status => 1 },
                  { :id => 2, :uuid => 'vol-xxxxxxx', :status => 0 },
                  { :id => 3, :uuid => 'vol-xxxxxxx', :status => 3 },
                  { :id => 4, :uuid => 'vol-xxxxxxx', :status => 2 },
                  { :id => 5, :uuid => 'vol-xxxxxxx', :status => 4 }]
            respond_to {|f|
              f.json { vl.to_json}
            }
          end
        end
      end

      collection :volume_snapshots do
        operation :index do
          description 'Show lists of the volume_snapshots'
          # params start, fixnum, optional 
          # params limit, fixnum, optional
          control do
            start = params[:start].to_i
            start = start < 1 ? 0 : start
            limit = params[:limit].to_i
            limit = limit < 1 ? nil : limit

            total_vs = Models::VolumeSnapshot.where(:account_id => @account.canonical_uuid)
            partial_vs = total_vs.dup.order(:id)
            partial_vs = partial_vs.limit(limit, start) if limit.is_a?(Integer)
            res = [{
              :owner_total => total_vs.count,
              :start => start,
              :limit => limit,
              :results => partial_vs.all.map { |vs| vs.to_api_document}
            }]
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
            raise InvalidRequestCredentials unless v.state == "available"

            vs = v.create_snapshot(@account.canonical_uuid)
            sp = vs.storage_pool

            res = Dcmgr.messaging.submit("zfs-handle.#{sp.node_id}", 'create_snapshot', vs.canonical_uuid)
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

            begin
              vs  = Models::VolumeSnapshot.delete_snapshot(@account.canonical_uuid, snapshot_id)
            rescue Models::VolumeSnapshot::RequestError => e
              logger.error(e)
              raise InvalidDeleteRequest
            end
            raise UnknownVolumeSnapshot if vs.nil?
            sp = vs.storage_pool

            res = Dcmgr.messaging.submit("zfs-handle.#{sp.node_id}", 'delete_snapshot', vs.canonical_uuid)
            response_to([vs.canonical_uuid])
          end
        end

        operation :status, :method =>:get, :member =>true do
          description 'Show the status'
          control do
            vs = [{ :id => 1, :uuid => 'snap-xxxxxxx', :status => 1 },
                  { :id => 2, :uuid => 'snap-xxxxxxx', :status => 0 },
                  { :id => 3, :uuid => 'snap-xxxxxxx', :status => 3 },
                  { :id => 4, :uuid => 'snap-xxxxxxx', :status => 2 },
                  { :id => 5, :uuid => 'snap-xxxxxxx', :status => 4 }]
            respond_to {|f|
              f.json { vs.to_json}
            }
          end
        end
      end

      collection :netfilter_groups do
        description 'Show lists of the netfilter_groups'
        operation :index do
          control do
            start = params[:start].to_i
            start = start < 1 ? 0 : start
            limit = params[:limit].to_i
            limit = limit < 1 ? nil : limit

            total_ds = Models::NetfilterGroup.where(:account_id=>@account.canonical_uuid)
            partial_ds = total_ds.dup.order(:id)
            partial_ds = partial_ds.limit(limit, start) if limit.is_a?(Integer)
            
            res = [{
                     :owner_total => total_ds.count,
                     :start => start,
                     :limit => limit,
                     :results=> partial_ds.all.map {|i| i.to_hash }
                   }]
            
            response_to(res)
          end
        end

        operation :show do
          description 'Show the netfilter_groups'
          control do
            g = find_by_uuid(:NetfilterGroup, params[:id])
            raise OperationNotPermitted unless examine_owner(g)

            response_to(g.to_hash)
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
            response_to(g.to_hash)
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

            # refresh netfilter_rules
            Dcmgr.messaging.event_publish('hva/netfilter_updated', :args=>[g.canonical_uuid])

            response_to(g.to_hash)
          end
        end

        operation :destroy do
          # params name, string
          description "Delete the netfilter group"

          control do
            Models::NetfilterGroup.lock!
            g = find_by_uuid(:NetfilterGroup, params[:id])

            raise UnknownNetfilterGroup if g.nil?
            raise NetfilterGroupNotPermitted if g.account_id != @account.canonical_uuid

            g.destroy
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
            start = params[:start].to_i
            start = start < 1 ? 0 : start
            limit = params[:limit].to_i
            limit = limit < 1 ? nil : limit

            total_ds = Models::StoragePool.where(:account_id=>@account.canonical_uuid)
            partial_ds = total_ds.dup.order(:id)
            partial_ds = partial_ds.limit(limit, start) if limit.is_a?(Integer)

            res = [{
              :owner_total => total_ds.count,
              :start => start,
              :limit => limit,
              :results=> partial_ds.all.map {|sp| sp.to_hash }
            }]

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
            response_to(vs.to_hash_document)
          end
        end
      end

      collection :ssh_key_pairs do
        description "List ssh key pairs in account"
        operation :index do
          # params start, fixnum, optional 
          # params limit, fixnum, optional
          control do
            start = params[:start].to_i
            start = start < 1 ? 0 : start
            limit = params[:limit].to_i
            limit = limit < 1 ? nil : limit
            
            total_ds = Models::SshKeyPair.where(:account_id=>@account.canonical_uuid)
            partial_ds = total_ds.dup.order(:id)
            partial_ds = partial_ds.limit(limit, start) if limit.is_a?(Integer)

            res = [{
              :owner_total => total_ds.count,
              :filter_total => total_ds.count,
              :start => start,
              :limit => limit,
              :results=> partial_ds.all.map {|i| i.to_hash }
            }]
            
            response_to(res)
          end
        end
        
        operation :show do
          description "Retrieve details about ssh key pair"
          # params :id required
          # params :format optional [openssh,putty]
          control do
            ssh = find_by_uuid(:SshKeyPair, params[:id])
            
            response_to(ssh.to_hash)
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
              :public_key=>keydata[:public_key]
            }
            if params[:download_once] != 'true'
              savedata[:private_key]=keydata[:private_key]
            end
            ssh = Models::SshKeyPair.create(savedata)
                                            
            # include private_key data in response even if
            # it's not going to be stored on DB.
            response_to(ssh.to_hash.merge(:private_key=>keydata[:private_key]))
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
            start = params[:start].to_i
            start = start < 1 ? 0 : start
            limit = params[:limit].to_i
            limit = limit < 1 ? nil : limit
            
            total_ds = Models::Network.where(:account_id=>@account.canonical_uuid)
            partial_ds = total_ds.dup.order(:id)
            partial_ds = partial_ds.limit(limit, start) if limit.is_a?(Integer)

            res = [{
              :owner_total => total_ds.count,
              :filter_total => total_ds.count,
              :start => start,
              :limit => limit,
              :results=> partial_ds.all.map {|i| i.to_hash }
            }]
            
            response_to(res)
          end
        end
        
        operation :show do
          description "Retrieve details about a network"
          # params :id required
          control do
            nw = find_by_uuid(:Network, params[:id])
            examine_owner(nw) || raise(OperationNotPermitted)
            
            response_to(nw.to_hash)
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
                                            
            response_to(nw.to_hash)
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
      
    end
  end
end
