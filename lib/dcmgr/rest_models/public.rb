module Dcmgr
  module RestModels::Public
    class FrontendServiceUser
      include Dcmgr::RestModels::Base
      public_name "frontend_service_users"
      set_protect false
      
      def authorize
        req = @orig_request
        fsuser = Dcmgr::FsuserAuthorizer.authorize(@orig_request)
      rescue Dcmgr::FsuserAuthorizer::NotAuthorized
        throw(:halt, [401, "Not authorized\n"])
      end
      
      public_action :get, :myself do
        fsuser = authorize
        {"name"=>fsuser}
      end

      public_action :get, :authorize do
        username, password = request[:_get_user], request[:_get_password]
        user = Models::User.find(:name=>username, :password=>password)
        if user
          {:id=>user.uuid, :name=>user.name}
        else
          nil
        end
      end
    end
    
    class Account
      include Dcmgr::RestModels::Base
      model Models::Account
      allow_keys :name, :memo, :enable, :contract_at

      public_action :get do
        find
      end

      public_action_withid :get do
        get
      end
      
      public_action_withid :put do
        update
      end
      
      public_action :post do
        account = create
        user.add_account(account)
        account
      end

      public_action_withid :delete do
        destroy
      end
    end

    class User
      include Dcmgr::RestModels::Base
      model Models::User
      allow_keys :name, :password, :enable, :email, :memo
      response_keys :uuid, :name, :enable, :email, :memo, :accounts

      public_action :post do
        create
      end
      
      public_action_withid :put do
        update
      end

      public_action :get, :myself do
        user
      end

      public_action_withid :get do
        get
      end

      public_action_withid :put, :add_account do
        target = Models::User[uuid]
        account_uuid = request[:_get_account]
        account = Models::Account[account_uuid]
        target.add_account(account)
        nil
      end
      
      public_action :get do
        if request[:_get_same_accounts] == "true"
          user.accounts.map{|o|o.users}.flatten
        else
          find
        end
      end

      public_action_withid :delete do
        destroy
      end

      public_action_withid :put, :add_tag do
        target = Models::User[uuid]
        tag_uuid = request[:_get_tag]
        tag = Models::Tag[tag_uuid]

        Dcmgr.logger.debug(tag.id)
        Dcmgr.logger.debug(target.id)
        Dcmgr.logger.debug(uuid)
        Dcmgr.logger.debug(tag)

        Models::TagMapping.create(:tag_id=>tag.id,
                                  :target_type=>TagMapping::TYPE_USER,
                                  :target_id=>target.id)
        []
      end
    end

    class KeyPair
      include Dcmgr::RestModels::Base
      model Models::KeyPair
      allow_keys :user
      response_keys :uuid, :user, :public_key, :private_key

      public_action :post do
        create
      end

      public_action_withid :get do
        get
      end

      public_action_withid :delete do
        destroy
      end

      public_action :get do
        find
      end
    end

    class NameTag
      include Dcmgr::RestModels::Base
      model Models::Tag
      public_name 'name_tags'
      allow_keys :account, :name

      public_action :post do
        create
      end

      public_action_withid :delete do
        destroy
      end
    end

    class AuthTag
      include Dcmgr::RestModels::Base
      model Models::Tag
      public_name 'auth_tags'
      allow_keys :account, :name, :role

      public_action :post do
        req_hash = request
        req_hash.delete :id
        tags = req_hash.delete :tags

        obj = _create(req_hash)
        
        # tag mappings
        Dcmgr.logger.debug("tags")      
        Dcmgr.logger.debug(tags)
        tags.each {|tag_uuid|
          tag = Models::Tag[tag_uuid]
          Dcmgr.logger.debug(uuid)
          Dcmgr.logger.debug(tag)
          if tag
            Models::TagMapping.create(:tag_id=>obj.id,
                                      :target_type=>Models::TagMapping::TYPE_TAG,
                                      :target_id=>tag.id)
          end
        }
        
        obj
      end
      
      public_action_withid :delete do
        destroy
      end
    end

    class TagAttribute
      include Dcmgr::RestModels::Base
      model Models::TagAttribute
      allow_keys :body
      response_keys :body, [:uuid, proc {|o| o.tag.uuid}]

      public_action :get do
        find
      end

      public_action_withid :get do
        ret = nil
        if uuid
          tag = Models::Tag[uuid]
          ret = tag.tag_attribute
          unless ret
            ret = Models::TagAttribute.create(:tag=>tag,
                                              :body=>'')
          end
        end
        ret
      end

      public_action_withid :put do
        obj = Models::Tag[uuid].tag_attribute
        req_hash = request
        req_hash.delete :id
        allow_keys.each{|key|
          if key == :account # duplicate create
            obj.account = Models::Account[req_hash[key]]
          elsif key == :user
            
          else req_hash.key?(key)
            obj.send('%s=' % key, req_hash[key])
          end
        }
        obj.save
      end
    end

    class Instance
      include Dcmgr::RestModels::Base
      model Models::Instance
      allow_keys :account, :user, :physical_host, :image_storage,
      :need_cpus, :need_cpu_mhz, :need_memory

      response_keys :uuid, :account, :user, :tags, :physical_host, :image_storage,
      :need_cpus, :need_cpu_mhz, :need_memory, :status, :ip, :hv_agent
      [:tags, proc {|o| o.tags.map{|t| t.uuid}}]

      public_action :get do
        find
      end
      
      public_action_withid :get do
        get
      end
      
      public_action_withid :put, :add_tag do
        target = Models::Instance[uuid]

        tag_uuid = request[:_get_tag]
        tag = Models::Tag[tag_uuid]

        Models::TagMapping.create(:tag_id=>tag.id,
                                  :target_type=>Models::TagMapping::TYPE_INSTANCE,
                                  :target_id=>target.id) if tag
        true
      end
      
      public_action_withid :put, :remove_tag do
        target = Models::Instance[uuid]
        tag_uuid = request[:_get_tag]
        tag = Models::Tag[tag_uuid]
        target.remove_tag(tag.id) if tag
        true
      end
      
      public_action :post do
        req_hash = request
        req_hash.delete :id
        instance = nil

        Dcmgr.db.transaction do
          req_hash[:image_storage] = Models::ImageStorage[req_hash[:image_storage]]
          instance = _create(req_hash)

          Dcmgr::hvchttp.open(instance.hv_agent.hv_controller.ip) {|http|
            begin
              res = http.run_instance(instance.hv_agent.ip,
                                      instance.uuid,
                                      instance.ip,
                                      instance.mac_address,
                                      instance.need_cpus, instance.need_cpu_mhz,
                                      instance.need_memory)
            rescue => e
              raise e
            end
            raise "can't controll hvc server" unless res.code == "200"
          }
          instance.status = Models::Instance::STATUS_TYPE_RUNNING
          
          Models::Log.create(:user=>user,
                             :account_id=>request[:account].to_i,
                             :target_uuid=>instance.uuid,
                             :action=>'run')
          
          instance.save
        end
        instance
      end
      
      public_action_withid :get do
        get
      end
      
      public_action_withid :put do
        update
      end

      public_action_withid :delete do
        destroy
      end

      public_action_withid :put, :reboot do
        [] # TODO: reboot action
      end

      public_action_withid :put, :shutdown do
        instance = Models::Instance[uuid]
        Dcmgr.logger.debug("terminating instance: #{instance.uuid}")

        instance.status = Models::Instance::STATUS_TYPE_TERMINATING
        instance.save
        
        Dcmgr::hvchttp.open(instance.hv_agent.hv_controller.ip) {|http|
          begin
            res = http.terminate_instance(instance.hv_agent.ip,
                                          instance.uuid)
          rescue => e
            raise e
          end
          raise "can't controll hvc server" unless res.code == "200"
        }
        
        Models::Log.create(:user=>user,
                           :account_id=>request[:account].to_i,
                           :target_uuid=>instance.uuid,
                           :action=>'shutdown')
        
        []
        
        # TODO check shutdown role
        #begin
        #  Dcmgr.evaluate(user, instance, :shutdown)
        #rescue Exception => e
        #	raise e
        #  Dcmgr::logger.debug("err! %s" % e)
        #  throw :halt, [400, e.to_s]
        #end
        #[]
      end

      public_action_withid :put, :snapshot do
        [] # TODO: snapshot action
      end
    end

    class HvController
      include Dcmgr::RestModels::Base
      model Models::HvController

      public_action :post do
        create
      end

      public_action_withid :delete do
        destroy
      end
    end

    class ImageStorage
      include Dcmgr::RestModels::Base
      model Models::ImageStorage
      allow_keys :image_storage_host, :storage_url

      public_action :get do
        find
      end

      public_action :post do
        req_hash = request
        req_hash.delete :id
        
        req_hash[:image_storage_host] = Models::ImageStorageHost[req_hash.delete(:image_storage_host)]

        image_storage = _create(req_hash)
        image_storage
      end

      public_action_withid :get do
        get
      end

      public_action_withid :delete do
        destroy
      end
    end

    class ImageStorageHost
      include Dcmgr::RestModels::Base
      model Models::ImageStorageHost
      allow_keys :name


      public_action :get do
        find
      end

      public_action :post do
        create
      end

      public_action_withid :get do
        get
      end

      public_action_withid :delete do
        destroy
      end
    end

    class PhysicalHost
      include Dcmgr::RestModels::Base
      model Models::PhysicalHost
      allow_keys :cpus, :cpu_mhz, :memory, :hypervisor_type
      
      public_action :get do
        find
      end

      public_action :post do
        create
      end

      public_action_withid :get do
        get
      end

      public_action_withid :delete do
        destroy
      end

      public_action_withid :put, :relate do
        user_uuid = request[:user]
        relate_user = Models::User[user_uuid]
        target = Models::PhysicalHost[uuid]
        target.relate_user_id = relate_user.id
        target.save
        target
      end
      
      public_action_withid :put, :remove_tag do
        target = Models::PhysicalHost[uuid]
        tag_uuid = request[:_get_tag]
        tag = Models::Tag[tag_uuid]
        target.remove_tag(tag) if tag
        []
      end
    end

    class LocationGroup
      include Dcmgr::RestModels::Base
      model Models::LocationGroup
      allow_keys :name
      
      public_action :get do
        Models::LocationGroup.all
      end
    end
  end
end
