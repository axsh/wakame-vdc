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

      def find_user(user_uuid)
        find_by_uuid(:User, user_uuid)
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
          # params like, string, optional
          # params sort, string, optional
          control do
            vl = [{
                    :id => 1,
                    :uuid => 'vol-00000000',
                    :storage_pool_id => '1',
                    :instance_id => '1',
                    :size => 1024,
                    :status => 1,
                    :state => 'available',
                    :export_path => 'vol-xxxxxxx',
                    :transport_information => { :iqn =>'iqn.1986-03.com.sun:02:d453f40c-40de-ca60-a377-c25f3af01fe5'},
                    :created_at => '2010-10-21 02:41:04',
                    :updated_at => '2010-10-21 02:41:04',
                    :visibility => 'public'
                  },{
                    :id => 2,
                    :uuid => 'vol-00000001',
                    :storage_pool_id => '1',
                    :instance_id => '2',
                    :size => 1024,
                    :status => 1,
                    :state => 'available',
                    :export_path => 'vol-xxxxxxx',
                    :transport_information => { :iqn =>'iqn.1986-03.com.sun:02:d453f40c-40de-ca60-a377-c25f3af01fe5'},
                    :created_at => '2010-10-21 02:41:04',
                    :updated_at => '2010-10-21 02:41:04',
                    :visibility => 'private'
                  }]
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
            vl = {
              :id => 1,
              :uuid => 'vol-00000000',
              :storage_pool_id => 1,
              :instance_id => 2,
              :size => 1024,
              :status => 1,
              :state => 1,
              :export_path => 'vol-00000000',
              :transport_information => { :iqn =>'iqn.1986-03.com.sun:02:d453f40c-40de-ca60-a377-c25f3af01fe5'},
              :created_at => '2010-10-21 02:41:04',
              :updated_at => '2010-10-21 02:41:04',
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
