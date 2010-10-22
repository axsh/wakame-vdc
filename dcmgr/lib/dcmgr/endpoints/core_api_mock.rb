# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'sinatra/rabbit'

require 'json'
require 'extlib/hash'

require 'dcmgr/endpoints/errors'

module Dcmgr
  module Endpoints
    class Mock
      def self.load(load)
        root = File.expand_path('../../')
        load = File::split(load)
        namespace = load[0]
        file = load[1] + '.json'
        dir = File.join(root,'fixtures','mock',namespace)
        jsonfile = File.join(dir,file)
        json = ''
        open(jsonfile) {|f| json = f.read }
        json
      end
    end

    class CoreAPI < Sinatra::Base
      register Sinatra::Rabbit

      disable :sessions
      disable :show_exceptions

      before do
        @params = parsed_request_body if request.post?
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

      def find_user(user_uuid)
        find_by_uuid(:User, user_uuid)
      end

      # Returns deserialized hash from HTTP body. Serialization fromat
      # is guessed from content type header. The query string params
      # is returned if none of content type header is in HTTP headers.
      # This method is called only when the request method is POST.
      def parsed_request_body
        mime = @mime_types.first
        case mime.to_sym
        when :'application/json', :'text/json'
          require 'json'
          hash = JSON.load(request.body)
          hash.to_mash
        when :'application/yaml', :'text/yaml'
          require 'yaml'
          hash = YAML.load(request.body)
          hash = hash.to_mash
        when '', nil
          # use query string as requested params if Content-Type
          # header was not sent.
          # ActiveResource library tells the one level nested hash which has
          # {'something key'=>real_params} so that dummy key is assinged here.
          hash = {:dummy=>@params}
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
      
      def pagenate(data,start,limit) 
        return data unless data.kind_of?(Array)
        if !start.nil? && !limit.nil?
          start = start.to_i
          limit = limit.to_i
          from = (start - 1)
          to = (from + limit -1)
          data = data[from..to]         
        end
        data
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
      
      collection :instances do
        operation :create do
          description 'Runs a new instance'
          # param :image_id, :required
          # param :instance_spec_id, :required
          control do
            hp = Models::HostPool.dataset.first
            raise NoCandidateTo
            i = hp.create_instance(params[:image_id])

            respond_to { |f|
              f.json { i.to_hash_document.to_json }
            }
          end
        end

        operation :show do
          #param :account_id, :string, :optional
          control do
            i = Modles::Instance[params[:id]]
            respond_to { |f|
              f.json { i.to_hash_document.to_json }
            }
          end
        end

        operation :destroy do
          description 'Shutdown the instance'
          control do
            i = find_by_uuid(:Instance, params[:id])

            respond_to { |f|
              f.json { i.to_hash_document.to_json }
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
          # params filter, string, optional
          # params target, string, optional
          # params sort, fixnum, optional
          # params start, fixnum, optional
          # params limit, fixnum, optional
          control do
            json = Mock.load('volumes/list')
            vl = JSON.load(json)
            vl = pagenate(vl,params[:start],params[:limit])
            respond_to { |f|
              f.json {vl.to_json}
            }
          end
        end

        operation :create do
          description 'Create the new volume'
          # params volume_size, string, required
          # params snapshot_id, string, optional
          # params private_pool_id, string, optional
          control do
            vl = { :status => 'creating', :messages => 'creating the new volume vol-xxxxxxx'}
            # vl = Models::Volume.create(:size=> params[:volume_size])
            # vl.state_machine.on_create
            respond_to { |f|
              f.json { vl.to_json}
            }
          end
        end

        operation :destroy do
          description 'Delete the volume'
          # params volume_id, string, required
          control do
            vl = { :status => 'deleting', :messages => 'deleting the volume vol-xxxxxxx'}
            respond_to { |f|
              f.json { vl.to_json}
            }
          end
        end

        operation :attach, :method =>:put, :member =>true do
          description 'Attachd the volume'
          # params volume_id, string, required
          # params instance_id, string, required
          control do
            vl = { :status => 'attaching', :message => 'attaching the volume of vol-xxxxxx to instance_id'}
            respond_to { |f|
              f.json { vl.to_json}
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
            raise UndefinedVolumeID if params[:volume_id].nil?
            json = Mock.load('volumes/details')
            vl = JSON.load(json)
            vl = vl[params[:volume_id]]
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
            @name = params[:id]
            g = (1..30).collect { |i|
              {
                :id          => i,
                :name        => "#{@name}_#{i}",
                :description => "desc_#{@name}_#{i}",
                :rule        => "\ntcp:22,22,0.0.0.0\ntcp:80,80,0.0.0.0\n#tcp:443,443,0.0.0.0\nudp:53,53,0.0.0.0\nicmp:-1,-1,0.0.0.0\n",
                :account_id  => "a-00000000",
                :created_at  => "Fri Oct 22 10:50:09 +0900 2010",
                :updated_at  => "Fri Oct 22 10:50:09 +0900 2010",
              }
            }

            respond_to { |f|
              f.json { g.to_json }
            }
          end
        end

        operation :show do
          description 'Show lists of the netfilter_groups'
          control do
            @name = params[:id]
            g = {
              :id          => 1,
              :name        => @name,
              :description => "desc_#{@name}",
              :rule        => "\ntcp:22,22,0.0.0.0\ntcp:80,80,0.0.0.0\n#tcp:443,443,0.0.0.0\nudp:53,53,0.0.0.0\nicmp:-1,-1,0.0.0.0\n",
              :account_id  => "a-00000000",
              :created_at  => "Fri Oct 22 10:50:09 +0900 2010",
              :updated_at  => "Fri Oct 22 10:50:09 +0900 2010",
            }
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
            @description = if params[:description]
                             params[:description]
                           else
                             "desc_#{@name}"
                           end
            @rule = if params[:rule]
                      params[:rule]
                    else
                      "\ntcp:22,22,0.0.0.0\ntcp:80,80,0.0.0.0\n#tcp:443,443,0.0.0.0\nudp:53,53,0.0.0.0\nicmp:-1,-1,0.0.0.0\n"
                    end

            g = {
              :id          => 1,
              :name        => @name,
              :description => @description,
              :rule        => @rule,
              :account_id  => "a-00000000",
              :created_at  => "Fri Oct 22 10:50:09 +0900 2010",
              :updated_at  => "Fri Oct 22 10:50:09 +0900 2010",
            }
            respond_to { |f|
              f.json { g.to_json }
            }
          end
        end

        operation :update do
          description "Update parameters for the netfilter group"
          # params description, string
          # params rule, string
          control do
            @name = params[:id]
            @description = nil
            @rule = nil

            if params[:description]
              @description = params[:description]
            else
              @description = "desc_#{@name}"
            end

            if params[:rule]
              @rule = params[:rule]
            else
              @rule = "\ntcp:22,22,0.0.0.0\ntcp:80,80,0.0.0.0\n#tcp:443,443,0.0.0.0\nudp:53,53,0.0.0.0\nicmp:-1,-1,0.0.0.0\n"
            end

            g = {
              :id          => 1,
              :name        => @name,
              :description => @description,
              :rule        => @rule,
              :account_id  => "a-00000000",
              :created_at  => "Fri Oct 22 10:50:09 +0900 2010",
              :updated_at  => "Fri Oct 22 10:50:09 +0900 2010",
            }
            respond_to { |f|
              f.json { g.to_json }
            }
          end
        end

        operation :destroy do
          description "Delete the netfilter group"

          control do
            @name = params[:id]
            g = {
              :id          => 1,
              :name        => @name,
              :description => "desc_#{@name}",
              :rule        => "\ntcp:22,22,0.0.0.0\ntcp:80,80,0.0.0.0\n#tcp:443,443,0.0.0.0\nudp:53,53,0.0.0.0\nicmp:-1,-1,0.0.0.0\n",
              :account_id  => "a-00000000",
              :created_at  => "Fri Oct 22 10:50:09 +0900 2010",
              :updated_at  => "Fri Oct 22 10:50:09 +0900 2010",
            }
            respond_to { |f|
              f.json { g.to_json }
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
            g = [
                 {:id => 1 ,:netfilter_group_id => 1, :permission => "tcp:22,22,0.0.0.0",  :created_at => "Fri Oct 22 11:15:10 +0900 2010", :updated_at => "Fri Oct 22 11:15:10 +0900 2010",},
                 {:id => 2, :netfilter_group_id => 1, :permission => "tcp:80,80,0.0.0.0",  :created_at => "Fri Oct 22 11:15:10 +0900 2010", :updated_at => "Fri Oct 22 11:15:10 +0900 2010",},
                 {:id => 3, :netfilter_group_id => 1, :permission => "udp:53,53,0.0.0.0",  :created_at => "Fri Oct 22 11:15:10 +0900 2010", :updated_at => "Fri Oct 22 11:15:10 +0900 2010",},
                 {:id => 4, :netfilter_group_id => 1, :permission => "icmp:-1,-1,0.0.0.0", :created_at => "Fri Oct 22 11:15:10 +0900 2010", :updated_at => "Fri Oct 22 11:15:10 +0900 2010",},
                ]
            respond_to { |f|
              f.json { g.to_json }
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
