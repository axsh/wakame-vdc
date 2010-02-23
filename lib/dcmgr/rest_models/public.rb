module Dcmgr
  class PublicAccount
    include RestModel
    model Account
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

  class PublicUser
    include RestModel
    model User
    allow_keys :name, :password, :enable
    response_keys :uuid, :name, :enable, :memo, :accounts

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
      target = User[uuid]
      account_uuid = request[:_get_account]
      account = Account[account_uuid]
      target.add_account(account)
      nil
    end
    
    public_action :get do
       user.accounts.map{|o|o.users}.flatten
    end
    
    public_action_withid :delete do
      destroy
    end

    public_action_withid :put, :add_tag do
      target = User[uuid]
      tag_uuid = request[:_get_tag]
      tag = Tag[tag_uuid]

      Dcmgr.logger.debug(tag.id)
      Dcmgr.logger.debug(target.id)
      Dcmgr.logger.debug(uuid)
      Dcmgr.logger.debug(tag)

      TagMapping.create(:tag_id=>tag.id,
                        :target_type=>TagMapping::TYPE_USER,
                        :target_id=>target.id)
      []
    end
  end

  class PublicKeyPair
    include RestModel
    model KeyPair
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

  class PublicNameTag
    include RestModel
    model Tag
    public_name 'name_tags'
    allow_keys :account, :name

    public_action :post do
      create
    end

    public_action_withid :delete do
      destroy
    end
  end

  class PublicAuthTag
    include RestModel
    model Tag
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
        tag = Tag[tag_uuid]
        Dcmgr.logger.debug(uuid)
        Dcmgr.logger.debug(tag)
        if tag
          TagMapping.create(:tag_id=>obj.id,
                            :target_type=>TagMapping::TYPE_TAG,
                            :target_id=>tag.id)
        end
      }
      
      obj
    end
    
    public_action_withid :delete do
      destroy
    end
  end

  class PublicTagAttribute
    include RestModel
    model TagAttribute
    allow_keys :body
    response_keys :body, [:uuid, proc {|o| o.tag.uuid}]

    public_action :get do
      find
    end

    public_action_withid :get do
      ret = nil
      if uuid
        tag = Tag[uuid]
        ret = tag.tag_attribute
        unless ret
          ret = TagAttribute.create(:tag=>tag,
                                    :body=>'')
          
        end
      end
      ret
    end

    public_action_withid :put do
      obj = Tag[uuid].tag_attribute
      req_hash = request
      req_hash.delete :id
      allow_keys.each{|key|
        if key == :account # duplicate create
          obj.account = Account[req_hash[key]]
        elsif key == :user
            
        else req_hash.key?(key)
          obj.send('%s=' % key, req_hash[key])
        end
      }
      obj.save
    end
  end

  class PublicInstance
    include RestModel
    model Instance
    allow_keys :account, :user, :physical_host, :image_storage,
               :need_cpus, :need_cpu_mhz, :need_memory

    public_action :get do
      find
    end
    
    public_action_withid :get do
      get
    end
    
    public_action_withid :put, :add_tag do
      target = Instance[uuid]

      tag_uuid = request[:_get_tag]
      tag = Tag[tag_uuid]

      TagMapping.create(:tag_id=>tag.id,
                        :target_type=>TagMapping::TYPE_INSTANCE,
                        :target_id=>target.id) if tag
    end
    
    public_action_withid :put, :remove_tag do
      target = Instance[uuid]
      tag_uuid = request[:_get_tag]
      tag = Tag[tag_uuid]
      target.remove_tag(tag.id) if tag
    end
    
    public_action :post do
      req_hash = request
      req_hash.delete :id
      instance = nil

      Dcmgr.db.transaction do
        req_hash[:image_storage] = ImageStorage[req_hash[:image_storage]]
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
        instance.status = Instance::STATUS_TYPE_RUNNING
        
        Log.create(:user=>user,
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
      instance = Instance[uuid]
      Dcmgr.logger.debug("terminating instance: #{instance.uuid}")

      instance.status = Instance::STATUS_TYPE_TERMINATING
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
      
      Log.create(:user=>user,
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

  class PublicHvController
    include RestModel
    model HvController

    public_action :post do
      create
    end

    public_action_withid :delete do
      destroy
    end
  end

  class PublicImageStorage
    include RestModel
    model ImageStorage
    allow_keys :image_storage_host, :storage_url

    public_action :get do
      find
    end

    public_action :post do
      req_hash = request
      req_hash.delete :id
      
      req_hash[:image_storage_host] = ImageStorageHost[req_hash.delete(:image_storage_host)]

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

  class PublicImageStorageHost
    include RestModel
    model ImageStorageHost
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

  class PublicPhysicalHost
    include RestModel
    model PhysicalHost
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
      relate_user = User[user_uuid]
      target = PhysicalHost[uuid]
      target.relate_user_id = relate_user.id
      target.save
      target
    end
    
    public_action_withid :put, :remove_tag do
      target = PhysicalHost[uuid]
      tag_uuid = request[:_get_tag]
      tag = Tag[tag_uuid]
      target.remove_tag(tag) if tag
      []
    end
  end

  class PublicLocationGroup
    include RestModel
    model LocationGroup
    allow_keys :name
    
    public_action :get do
      LocationGroup.all
    end
  end
end
