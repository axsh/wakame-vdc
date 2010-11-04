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

      # I am not going to use error(ex, &blk) hook since it works only
      # when matches the Exception class exactly. I expect to match
      # whole subclasses of APIError so that override handle_exception!().
      def handle_exception!(boom)
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
            respond_to { |f|
              f.json { a.to_hash_document.to_json }
            }
          end
        end

        operation :create do
          description 'Register a new account'
          control do
            a = Models::Account.create()
            respond_to { |f|
              f.json { a.to_hash_document.to_json }
            }
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

            respond_to { |f|
              f.json { {} }
            }
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
            limit = limit < 1 ? 10 : limit
            
            total_ds = Models::Instance.where(:account_id=>@account.canonical_uuid)
            partial_ds  = total_ds.dup.limit(limit, start).order(:id)

            res = [{
              :owner_total => total_ds.count,
              :start => start,
              :limit => limit,
              :results=> partial_ds.all.map {|i| i.to_api_document }
            }]
            
            respond_to { |f|
              f.json {res.to_json}
            }
          end
        end

        operation :create do
          description 'Runs a new VM instance'
          # param :image_id, :required
          # param :instance_spec_id, :required
          # param :host_pool_id, :optional
          # param :host_name, :optional
          control do
            wmi = find_by_uuid(:Image, params[:image_id])

            hp = if params[:host_pool_id]
                   hp = Models::HostPool[params[:host_pool_id]]
                 else
                   # TODO: schedule a host pool owned by SharedPool account.
                 end
            
            raise UnknownHostPool, "Could not find host pool: #{params[:host_pool_id]}" if hp.nil?
            
            spec = find_by_uuid(:InstanceSpec, 'is-kpf0pasc')

            case wmi.boot_dev_type
            when Models::Image::BOOT_DEV_SAN
              # create new volume from snapshot.
              snapshot_id = wmi.source[:snapshot_id]
              vol = create_volume_from_snapshot(@account.canonical_uuid, snapshot_id)

              inst = hp.create_instance(@account, wmi, spec) do |i|
                # TODO: do not use rand() to decide vnc port.
                i.runtime_config = {:vnc_port=>rand(2000), :telnet_port=> (rand(2000) + 2000)}
              end

              vol.instance = inst
              vol.save
              res = Dcmgr.messaging.submit("kvm-handle.#{hp.node_id}", 'run_vol_store', inst.canonical_uuid, vol.canonical_uuid)
            when Models::Image::BOOT_DEV_LOCAL
              inst = hp.create_instance(@account, wmi, spec) do |i|
                # TODO: do not use rand() to decide vnc port.
                i.runtime_config = {:vnc_port=>rand(2000), :telnet_port=> (rand(2000) + 2000)}
              end
              res = Dcmgr.messaging.submit("kvm-handle.#{hp.node_id}", 'run_local_store', inst.canonical_uuid)
            else
              raise "Unknown boot type"
            end
            respond_to { |f|
              f.json { inst.to_api_document.to_json }
            }
          end
        end

        operation :show do
          #param :account_id, :string, :optional
          control do
            i = find_by_uuid(:Instance, params[:id])
            raise UnknownInstance if i.nil?
            
            respond_to { |f|
              f.json { i.to_api_document.to_json }
            }
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
            res = Dcmgr.messaging.submit("kvm-handle.#{i.host_pool.node_id}", 'terminate', i.canonical_uuid)
            respond_to { |f|
              f.json { i.canonical_uuid }
            }
          end
        end

        operation :reboot, :method=>:put, :member=>true do
          description 'Reboots the instance'
          control do
            i = find_by_uuid(:Instance, params[:id])
          end
        end
      end

      collection :images do
        operation :create do
          description 'Register new machine image'
          control do
            raise NotImplementedError
          end
        end

        operation :index do
          description 'Show list of machine images'
          control do
            start = params[:start].to_i
            start = start < 1 ? 0 : start
            limit = params[:limit].to_i
            limit = limit < 1 ? 10 : limit
            
            total_ds = Models::Image.where(:account_id=>@account.canonical_uuid)
            partial_ds  = total_ds.dup.limit(limit, start).order(:id)

            res = [{
              :owner_total => total_ds.count,
              :start => start,
              :limit => limit,
              :results=> partial_ds.all.map {|i| i.to_hash }
            }]
            
            respond_to { |f|
              f.json {res.to_json}
            }
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
            respond_to { |f|
              f.json { i.to_hash.to_json }
            }
          end
        end

        operation :destroy do
          description 'Delete a machine image'
          control do
            i = find_by_uuid(:Image, params[:id])
            if examine_owner(i)
              i.delete
            else
              raise OperationNotPermitted
            end
          end
        end
      end
        
      collection :host_pools do
        operation :create do
          description 'Register a new physical host'
          # param :
          control do
            raise OperationNotPermitted unless @account.is_a?(Models::Account::SystemAccount::DatacenterAccount)
            input = parsed_request_body

            hp = Models::HostPool.create(:cpu_cores=>input[:cpu_cores],
                                         :memory_size=>input[:memory_size],
                                         :arch=>input[:arch],
                                         :hypervisor=>input[:hypervisor]
                                         )
            respond_to { |f|
              f.json{ hp.to_hash.to_json }
            }
          end
        end

        operation :show do
          description 'Show status of the host'
          #param :account_id, :string, :optional
          control do
            raise OperationNotPermitted unless @account.is_a?(Models::Account::SystemAccount::DatacenterAccount)

            hp = find_by_uuid(:HostPool, params[:id])
            respond_to { |f|
              f.json { hp.to_hash.to_json }
            }
          end
        end

        operation :destroy do
          description 'Unregister the existing host'
          control do
            raise OperationNotPermitted unless @account.is_a?(Models::Account::SystemAccount::DatacenterAccount)

            hp = find_by_uuid(:HostPool, params[:id])
            if hp.depend_resources?
              raise ""
            end
            hp.destroy
          end
        end

        operation :update do
          description 'Update parameters for the host'
          # param :cpu_cores, :optional
          # param :memory_size, :optional
          control do
            raise OperationNotPermitted unless @account.is_a?(Models::Account::SystemAccount::DatacenterAccount)

            hp = find_by_uuid(:HostPool, params[:id])
            if params[:cpu_cores]
              hp.offering_cpu_cores = params[:cpu_cores].to_i
            end
            if params[:memory_size]
              hp.offering_memory_size = params[:memory_size].to_i
            end

            hp.save
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
            limit = limit < 1 ? 10 : limit

            total_v = Models::Volume.where(:account_id => @account.canonical_uuid)
            partial_v = total_v.dup.limit(limit, start).order(:id)
            res = [{
              :owner_total => total_v.count,
              :start => start,
              :limit => limit,
              :results => partial_v.all.map { |v| v.to_hash_document}
            }]
            respond_to { |f|
              f.json { res.to_json}
            }
          end
        end

        operation :show do
          description 'Show the volume status'
          # params id, string, required
          control do
            volume_id = params[:id]
            raise UndefinedVolumeID if volume_id.nil?
            v = find_by_uuid(:Volume, volume_id)
            respond_to { |f|
              f.json { v.to_hash_document.to_json}
            }
          end
        end

        operation :create do
          description 'Create the new volume'
          # params volume_size, string, required
          # params snapshot_id, string, optional
          # params storage_pool_id, string, optional
          control do
            if params[:snapshot_id]
              v = create_volume_from_snapshot(@account.canonical_uuid, params[:snapshot_id])
              sp = v.storage_pool
            elsif params[:volume_size]
              raise InvalidVolumeSize if !(Dcmgr.conf.create_volume_max_size.to_i >= params[:volume_size].to_i) || !(params[:volume_size\
].to_i >= Dcmgr.conf.create_volume_min_size.to_i)
              if params[:storage_pool_id]
                sp = find_by_uuid(:StoragePool, params[:storage_pool_id])
                raise StoragePoolNotPermitted if sp.account_id != @account.canonical_uuid
              end
              raise UnknownStoragePool if sp.nil?
              begin
                v = sp.create_volume(@account.canonical_uuid, params[:volume_size])
              rescue Models::Volume::DiskError => e
                Dcmgr.logger.error(e)
                raise OutOfDiskSpace
              rescue Sequel::DatabaseError => e
                Dcmgr.logger.error(e)
                raise DatabaseError
              end
            else
              raise UndefinedRequiredParameter
            end

            Dcmgr.messaging.request("job.sta-loader.#{sp.values[:node_id]}", 'create', v.canonical_uuid) do |req|
              req.oneshot = true
            end
            respond_to { |f|
              f.json { v.to_hash_document.to_json}
            }
          end
        end

        operation :destroy do
          description 'Delete the volume'
          # params id, string, required
          control do
            volume_id = params[:id]
            raise UndefinedVolumeID if volume_id.nil?

            begin
              v  = Models::Volume.delete_volume(@account.canonical_uuid, volume_id)
            rescue Models::Volume::RequestError => e
              Dcmgr.logger.error(e)
              raise InvalidDeleteRequest
            end
            raise UnknownVolume if v.nil?
            sp = v.storage_pool
            Dcmgr.messaging.request("job.sta-loader.#{sp.values[:node_id]}", 'delete', v.canonical_uuid) do |req|
              req.oneshot = true
            end
            respond_to { |f|
              f.json { v.values.to_json}
            }
          end
        end

        operation :attach, :method =>:put, :member =>true do
          description 'Attachd the volume'
          # params id, string, required
          # params instance_id, string, required
          control do
            require 'yaml'
            raise UndefinedInstanceID if params[:instance_id].nil?
            raise UndefinedVolumeID if params[:id].nil?
            
            i = find_by_uuid(:Instance, params[:instance_id])
            raise UnknownInstance if i.nil?

            v = find_by_uuid(:Volume, params[:id])
            raise UnknownVolume if v.nil?

            v.instance = i
            v.save

            opt = v.values.dup
            opt[:transport_information] = YAML.load(opt[:transport_information])
            res = Dcmgr.messaging.submit("kvm-handle.#{i.host_pool.node_id}", 'attach', i.canonical_uuid, v.canonical_uuid)

            respond_to { |f|
              f.json { v.values.to_json}
            }
          end
        end

        operation :detach, :method =>:put, :member =>true do
          description 'Detachd the volume'
          # params volume_id, string, required
          control do
            vl = { :status => 'detaching', :message => 'detaching the volume of instance_id to vol-xxxxxx'}
            respond_to { |f|
              f.json { vl.to_json}
            }
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
            limit = limit < 1 ? 10 : limit

            total_vs = Models::VolumeSnapshot.where(:account_id => @account.canonical_uuid)
            partial_vs = total_vs.dup.limit(limit, start).order(:id)
            res = [{
              :owner_total => total_vs.count,
              :start => start,
              :limit => limit,
              :results => partial_vs.all.map { |vs| vs.to_hash_document}
            }]
            respond_to { |f|
              f.json { res.to_json}
            }
          end
        end

        operation :show do
          description 'Show the volume status'
          # params id, string, required
          control do
            snapshot_id = params[:id]
            raise UndefinedVolumeSnapshotID if snapshot_id.nil?
            vs = find_by_uuid(:VolumeSnapshot, snapshot_id)
            respond_to { |f|
              f.json { vs.to_hash_document.to_json}
            }
          end
        end

        operation :create do
          description 'Create a new volume snapshot'
          # params volume_id, string, required
          # params storage_pool_id, string, optional
          control do
            raise UndefinedVolumeID if params[:volume_id].nil?

            v = find_by_uuid(:Volume, params[:volume_id])
            raise UnknownVolume if v.nil?

            vs = v.create_snapshot(@account.canonical_uuid)
            sp = vs.storage_pool

            Dcmgr.messaging.request("job.sta-loader.#{sp.node_id}", 'create_snapshot', vs.canonical_uuid) do |req|
              req.oneshot = true
            end
            respond_to { |f|
              f.json { vs.to_hash_document.to_json}
            }
          end
        end

        operation :destroy do
          description 'Delete the volume snapshot'
          # params id, string, required
          control do
            snapshot_id = params[:id]
            raise UndefindVolumeSnapshotID if snapshot_id.nil?

            vs = find_by_uuid(:VolumeSnapshot, snapshot_id)
            raise UnknownVolumeSnapshot if vs.nil?
            vs = vs.delete_snapshot
            sp = vs.storage_pool
            Dcmgr.messaging.request("job.sta-loader.#{sp.node_id}", 'delete_snapshot', vs.canonical_uuid) do |req|
              req.oneshot = true
            end
            respond_to { |f|
              f.json { vs.to_hash_document.to_json }
            }
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
            all   = params[:all].to_i

            start = params[:start].to_i
            start = start < 1 ? 0 : start
            limit = params[:limit].to_i
            limit = limit < 1 ? 10 : limit

            # show all?
            if all != 0
              g = Models::NetfilterGroup.filter(:account_id => @account.canonical_uuid).all.collect { |row| row.to_tiny_hash }
              respond_to { |f|
                f.json { g.to_json }
              }
            else
              total_ds = Models::NetfilterGroup.where(:account_id=>@account.canonical_uuid)
              partial_ds  = total_ds.dup.limit(limit, start).order(:id)

              res = [{
                       :owner_total => total_ds.count,
                       :start => start,
                       :limit => limit,
                       :results=> partial_ds.all.map {|i| i.to_hash }
                     }]

              respond_to { |f|
                f.json {res.to_json}
              }
            end
          end
        end

        operation :show do
          description 'Show the netfilter_groups'
          control do
            @name = params[:id]
            g = Models::NetfilterGroup.filter(:name => @name, :account_id => @account.canonical_uuid).first

            respond_to { |f|
              f.json { g.to_json }
            }
          end
        end

        operation :create do
          description 'Register a new netfilter_group'
          # params name, string
          # params description, string
          # params rule, string
          control do
            raise UndefinedNetfilterGroup if params[:name].nil?

            @name = params[:name]
            # TODO: validate @name. @name can use [a-z] [A-Z] '_' '-'
            # - invalidate? -> raise InvalidCharacterOfNetfilterGroupName

            g = Models::NetfilterGroup.filter(:name => @name, :account_id => @account.canonical_uuid).first
            raise DuplicatedNetfilterGroup unless g.nil?

            g = Models::NetfilterGroup.create_group(@account.canonical_uuid, params)
            respond_to { |f|
              f.json { g.values.to_json }
            }
          end
        end

        operation :update do
          description "Update parameters for the netfilter group"
          # params name, string
          # params description, string
          # params rule, string
          control do
            @name = params[:id]
            g = Models::NetfilterGroup.filter(:name => @name, :account_id => @account.canonical_uuid).first

            raise UnknownNetfilterGroup if g.nil?

            g.name = @name
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

            respond_to { |f|
              f.json { g.values.to_json }
            }
          end
        end

        operation :destroy do
          # params name, string
          description "Delete the netfilter group"

          control do
            @name = params[:id]
            g = Models::NetfilterGroup.filter(:name => @name, :account_id => @account.canonical_uuid).first

            raise UnknownNetfilterGroup if g.nil?
            raise NetfilterGroupNotPermitted if g.account_id != @account.canonical_uuid

            respond_to { |f|
              f.json { g.destroy_group.values.to_json }
            }
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

            respond_to { |f|
              f.json { rules.to_json }
            }
          end
        end
      end

      collection :private_pools do
        operation :show do
          description 'Show lists of the private_pools'
          control do
            pp = [{
                    :id => 1,
                    :account_id => 'u-xxxxxxx',
                    :storage_pool_id => 1,
                    :created_at => 'Fri Sep 10 14:50:11 +0900 2010',
                    :updated_at => 'Fri Sep 10 14:50:11 +0900 2010'
                  },{
                    :id => 2,
                    :account_id => 'u-xxxxxxx',
                    :storage_pool_id => 23,
                    :created_at => 'Fri Sep 10 14:50:11 +0900 2010',
                    :updated_at => 'Fri Sep 10 14:50:11 +0900 2010'
                  },{
                    :id => 2,
                    :account_id => 'u-xxxxxxx',
                    :storage_pool_id => 150,
                    :created_at => 'Fri Sep 10 14:50:11 +0900 2010',
                    :updated_at => 'Fri Sep 10 14:50:11 +0900 2010'
                  }]
            respond_to { |f|
              f.json { pp.to_json}
            }
          end
        end
      end

      collection :ssh_key_pair do
        description "List ssh key pairs in account"
        operation :index do
          # params start, fixnum, optional 
          # params limit, fixnum, optional
          control do
            start = params[:start].to_i
            start = start < 1 ? 0 : start
            limit = params[:limit].to_i
            limit = limit < 1 ? 10 : limit
            
            total_ds = Models::SshKeyPair.where(:account_id=>@account.canonical_uuid)
            partial_ds  = total_ds.dup.limit(limit, start).order(:id)

            res = [{
              :owner_total => total_ds.count,
              :filter_total => total_ds.count,
              :start => start,
              :limit => limit,
              :results=> partial_ds.all.map {|i| i.to_api_document }
            }]
            
            respond_to { |f|
              f.json {res.to_json}
            }
          end
        end
        
        operation :show do
          description "Retrieve details about ssh key pair"
          # params :id required
          # params :format optional [openssh,putty]
          control do
            ssh = find_by_uuid(:SshKeyPair, params[:id])
            
            respond_to { |f|
              f.json {ssh.to_hash.to_json}
            }
          end
        end
        
        operation :create do
          description "Create ssh key pair information"
          # params :name required key name (<100 chars)
          # params :download_once optional set true if you do not want
          #        to save private key info on database.
          control do
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
                                            
            respond_to { |f|
              # include private_key data in response even if
              # it's not going to be stored on DB.
              f.json {ssh.to_hash.merge(:private_key=>keydata[:private_key]).to_json}
            }
          end
        end
        
        operation :destroy do
          description "Remove ssh key pair information"
          # params :id required
          control do
            ssh = find_by_uuid(:SshKeyPair, params[:id])
            if examine_owner(ssh)
              ssh.destroy
            else
              raise OperationNotPermitted
            end
            
            respond_to { |f|
              f.json {ssh.to_hash.to_json}
            }
          end
        end

      end

    end
  end
end
