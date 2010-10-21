# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'sinatra/rabbit'

require 'json'
require 'extlib/hash'

require 'dcmgr/endpoints/errors'

module Dcmgr
  module Endpoints
    class CoreAPI < Sinatra::Base
      register Sinatra::Rabbit

      disable :sessions
      disable :show_exceptions

      before do
        @params = parsed_request_body
        request.env['dcmgr.frotend_system.id'] = 1
        request.env['HTTP_X_VDC_REQUESTER_TOKEN']='u-xxxxxx'
        request.env['HTTP_X_VDC_ACCOUNT_UUID']='a-00000000'
      end

      before do
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

      def parsed_request_body
        return @params if request.request_method != 'POST'
        raise "no hint for body content to be parsed" if @mime_types.nil? || @mime_types.empty?
        mime = @mime_types.first
        case mime.to_sym
        when :'application/json', :'text/json'
          require 'json'
          hash = JSON.load(request.body)
          hash.to_mash
        when :'application/yaml', :'text/yaml'
          require 'yaml'
          hash = YAML.load(request.body)
          hash.to_mash
        else
          raise "Unsupported format in request.body: #{mime}"
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
            inst = hp.create_instance(wmi, spec) do |i|
              i.runtime_config = {:vnc_port=>rand(2000)}
            end

            case wmi.boot_dev_type
            when Models::Image::BOOT_DEV_SAN
              # create new volume from 
              # snapshot_id = wmi.source[:snapshot_id]
              # vol = create_volume_from_snapshot(snapshot_id)
              
              vol_id = wmi.source[:vol_id]
              res = Dcmgr.messaging.submit("kvm-handle.#{hp.node_id}", 'run_vol_store', inst.canonical_uuid, vol_id)
            when Models::Image::BOOT_DEV_LOCAL
              res = Dcmgr.messaging.submit("kvm-handle.#{hp.node_id}", 'run_local_store', inst.canonical_uuid)
            else
              raise "Unknown boot type"
            end
            respond_to { |f|
              f.json { inst.to_hash.to_json }
            }
          end
        end

        operation :show do
          #param :account_id, :string, :optional
          control do
            i = Modles::Instance[params[:id]]
            raise UnknownInstance if i.nil?
            
            respond_to { |f|
              f.json { i.to_hash.to_json }
            }
          end
        end

        operation :destroy do
          description 'Shutdown the instance'
          control do
            i = find_by_uuid(:Instance, params[:id])

            respond_to { |f|
              f.json { i.to_hash.to_json }
            }
          end
        end

        operation :update do
          description 'Change vcpu cores or memory size on the instance'
          control do
            i = find_by_uuid(:Instance, params[:id])
          end
        end

        operation :reboot, :method=>:get, :member=>true do
          description 'Reboots the instance'
          control do
            i = find_by_uuid(:Instance, params[:id])
          end
        end

        operation :resume, :method=>:get, :member=>true do
          description 'Resume the suspending instance'
          control do
            i = find_by_uuid(:Instance, params[:id])
          end
        end

        operation :suspend, :method=>:get, :member=>true do
          description 'Suspend the instance'
          control do
            i = find_by_uuid(:Instance, params[:id])
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
              f.json{ hp.to_hash_document.to_json }
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
              f.json { hp.to_hash_document.to_json }
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
        operation :show do
          description 'Show lists of the volume'
          # params visibility, string, optional
          # params like, string, optional
          # params sort, string, optional
          # params start, fixnum, optional 
          # params limit, fixnum, optional
          control do
            vl = Models::Volume.dataset.all.map{|row|
              row.values
            }
            respond_to { |f|
              f.json {vl.to_json}
            }
          end
        end

        operation :create do
          description 'Create the new volume'
          # params volume_size, string, required
          # params snapshot_id, string, optional
          # params storage_pool_id, string, optional
          control do
            raise UndefinedVolumeSize if params[:volume_size].nil?
            
            if params[:snapshot_id]
              vs = find_by_uuid(:VolumeSnapshot, params[:snapshot_id])
              sp = vs.storage_pool
            else
              if params[:storage_pool_id]
                sp = find_by_uuid(:StoragePool, params[:storage_pool_id])
                raise StoragePoolNotPermitted if sp.account_id != @account.canonical_uuid
              end
              raise UnknownStoragePool if sp.nil?
            end

            volume_size = (vs.values[:size] if !vs.nil?) || params[:volume_size]
            snapshot_id = (vs.canonical_uuid if !vs.nil?) || nil
            begin
              v = sp.create_volume(@account.canonical_uuid, params[:volume_size], snapshot_id)
            rescue Models::Volume::DiskError => e
              Dcmgr.logger.error(e)
              raise OutOfDiskSpace
            rescue Sequel::DatabaseError => e
              Dcmgr.logger.error(e)
              raise DatabaseError
            end

            Dcmgr.messaging.submit("sta-loader.#{sp.values[:agent_id]}", 'create', v.canonical_uuid, snapshot_id)
            respond_to { |f|
              f.json { v.values.to_json}
            }
          end
        end

        operation :destroy do
          description 'Delete the volume'
          # params volume_id, string, required
          control do
            raise UndefinedVolumeID if params[:volume_id].nil?

            begin
              v  = Models::Volume.delete_volume(@account.canonical_uuid, params[:volume_id])
            rescue Models::Volume::RequestError => e
              Dcmgr.logger.error(e)
              raise InvalidDeleteRequest
            end
            raise UnknownVolume if v.nil?

            sp = v.storage_pool

            Dcmgr.messaging.request("sta-loader.#{sp.values[:agent_id]}", 'delete', v.canonical_uuid) do |req|
              req.oneshot = true
            end
            # 選択したvolumeの削除をstorage_agentに送る
            respond_to { |f|
              f.json { v.values.to_json}
            }
          end
        end

        operation :attach, :method =>:put, :member =>true do
          description 'Attachd the volume'
          # params volume_id, string, required
          # params instance_id, string, required
          control do
            require 'yaml'
            raise UndefinedInstanceID if params[:instance_id].nil?
            raise UndefinedVolumeID if params[:volume_id].nil?
            
            i = find_by_uuid(:Instance, params[:instance_id])
            raise UnknownInstance if i.nil?

            v = i.find_volume(@account.canonical_uuid, params[:volume_id])
            raise UnknownVolume if v.nil?

            opt = v.values.dup
            opt[:transport_information] = YAML.load(opt[:transport_information])
            Dcmgr.messaging.request("job.kvm-handle.hva-192.168.1.181", 'attach', opt) do |req|
              req.oneshot = true
            end

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

        operation :detail, :method =>:get, :member =>true do
          description 'Show the volume status'
          # params volume_id, string, required
          control do
            vl = {
              :id => 1,
              :uuid => 'vol-00000000',
              :storage_pool_id => 1,
              :instance_id => 2,
              :size => 10,
              :status => 1,
              :state => 1,
              :export_path => 'vol-xxxxxxx',
              :transport_information => { :iqn =>'iqn.1986-03.com.sun:02:d453f40c-40de-ca60-a377-c25f3af01fe5'},
              :created_at => 'Fri Sep 10 14:50:11 +0900 2010',
              :updated_at => 'Fri Sep 10 14:50:11 +0900 2010',
              :visibility => 'public'
            }
            respond_to { |f|
              f.json { vl.to_json}
            }
          end
        end
      end

      collection :volume_snapshots do
        operation :show do
          description 'Show lists of the volume_snapshots'
          # params visibility, string, optional
          # params like, string, optional
          # parms sort, string, optional
          control do
            vs = [{
                    :id => 1,
                    :uuid => 'snap-00000000',
                    :storage_pool_id => 1,
                    :origin_volume_uuid => 'vol-xxxxxxx',
                    :size => 10,
                    :status => 1,
                    :created_at => 'Fri Sep 10 14:50:11 +0900 2010',
                    :updated_at => 'Fri Sep 10 14:50:11 +0900 2010',
                    :visibility => 'public'
                  },{
                    :id => 1,
                    :uuid => 'snap-00000000',
                    :storage_pool_id => 2,
                    :origin_volume_id => 'vol-xxxxxxx',
                    :size => 10,
                    :status => 1,
                    :created_at => 'Fri Sep 10 14:50:11 +0900 2010',
                    :updated_at => 'Fri Sep 10 14:50:11 +0900 2010',
                    :visibility => 'private'
                  }]
            respond_to { |f|
              f.json { vs.to_json }
            }
          end
        end

        operation :create do
          description 'Create a new volume snapshot'
          # params volume_id, string, required
          # params pool_id, string, optional
          control do
            vs = { :status => 'creating', :message => 'creating the new snapshot'}
            respond_to { |f|
              f.json { vs.to_json }
            }
          end
        end

        operation :destroy do
          description 'Delete the volume snapshot'
          # params snapshot_id, string, required
          control do
            vs = { :status => 'deleting', :message => 'deleting the snapshot'}
            respond_to { |f|
              f.json { vs.to_json }
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

        operation :detail, :method =>:get, :member =>true do
          description 'Show the volume status'
          # params volume_id, string, required
          control do
            vs = {
              :id => 1,
              :uuid => 'snap-00000000',
              :storage_pool_id => 1,
              :origin_volume_uuid => 'vol-xxxxxxx',
              :size => 10,
              :status => 1,
              :created_at => 'Fri Sep 10 14:50:11 +0900 2010',
              :updated_at => 'Fri Sep 10 14:50:11 +0900 2010',
              :visibility => 'public'
            }
            respond_to { |f|
              f.json { vs.to_json}
            }
          end
        end

      end

      collection :netfilter_groups do
        operation :index do
          control do
          end
        end

        operation :show do
          description 'Show lists of the netfilter_groups'
          control do
            @name = params[:id]
            g = Models::NetfilterGroup.filter(:name => @name, :account_id => @account.canonical_uuid).first

            respond_to { |f|
              f.json { g.values.to_json }
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

            respond_to { |f|
              f.json { g.values.to_json }
            }
          end
        end

        operation :destroy do
          # params name, string
          description "Delete the netfilter group"

          control do
            g = Models::NetfilterGroup[params[:id]]

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

    end
  end
end
