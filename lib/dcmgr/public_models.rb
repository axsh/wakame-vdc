require 'json'
require 'dcmgr/authorize'

module Dcmgr
  module PublicModel
    module ClassMethods
      def get_actions
        @public_actions.each{|method, path, args, action|
          yield [method, path, route(self, action)]
        }
      end
      
      def public_action(method, name=nil, *args, &block)
        @public_actions ||= []
        @public_actions << [method, url_all(name), args, block]
      end
      
      def public_action_withid(method, name=nil, *args, &block)
        @public_actions ||= []
        @public_actions << [method, url_id(name), args, block]
      end
      
      def url_all(action_name=nil)
        if action_name
          "/#{public_name}/#{action_name}.json"
        else
          "/#{public_name}.json"
        end          
      end
      
      def url_id(action_name=nil)
        if action_name
          %r{/#{public_name}/(\w+-\w+)/#{action_name}.json}
        else
          %r{/#{public_name}/(\w+-\w+).json}
        end
      end

      def allow_keys(keys=nil)
        return @allow_keys unless keys
        @allow_keys = keys
      end
      
      def model(model_class=nil)
        return @model unless model_class
        @model = model_class
      end
      
      def public_name(name=nil)
        return (@public_name or @model.table_name.to_s) unless name
        @public_name = name
      end
      
      def route(public_class, block)
        Dcmgr::logger.debug "route: %s, %s, %s" % [self, public_class, block]
        proc do |id|
          logger.debug "url: " + request.url
          protected!
          
          obj = public_class.new(authorized_user, request)
          obj.uuid = id if id
          begin
            ret = obj.instance_eval(&block)
          rescue Sequel::ValidationFailed => e
            logger.debug "err! %s" % e.to_s
            throw :halt, [400, e.to_s]
          end
          logger.debug "response(inspect): " + ret.inspect
          json_ret = public_class.json_render(ret)
          logger.debug "response(json): " + json_ret
          json_ret
        end
      end
      
      def json_render(obj)
        def model2hash i
          h = Hash.new
          i.keys.each{ |key|
            h[key] = i.send(key)
          }

          # strip id, change uuid to id
          id = h.delete :id
          uuid = h.delete :uuid
          h[:id] = uuid if uuid
          h
        end
        
        if obj.is_a? Array
          ret = obj.collect{|i| model2hash(i)}
        else
          ret = model2hash(obj)
        end
        ret.to_json
      end
    end

    def self.included(mod)
      mod.extend ClassMethods
    end
    
    attr_accessor :uuid
    attr_accessor :user
    attr_accessor :request
    
    def model
      self.class.model
    end

    def allow_keys
      self.class.allow_keys
    end

    def format_object(object)
      if object
        def object.keys
          keys = super()
          # change from xxx_id to xxx
          keys.map! {|k|
            if /^(.*)_id$/ =~ k.to_s
              $1.to_sym
            else
              k
            end
          }
          keys.push :tags
        end
        def object.tags
          super().map{|t| t.uuid} # format only tags uuid
        end
        def object.account
          super().uuid
        end
        def object.relate_user
          if super
            super.uuid
          else
            nil
          end
        end
        def object.physical_host
          super().uuid
        end
      end
      object
    end
    
    def list
      model.all.map{|o| format_object(o)}
    end
    
    def get
      format_object(model[uuid])
    end

    def _create(req_hash=nil)
      unless req_hash
        req_hash = json_request
        req_hash.delete 'id'
      end
      
      obj = model.new

      if allow_keys
        Dcmgr.logger.debug("_create: set fields:")
        allow_keys.each{|k|
          Dcmgr.logger.debug(" key: %s" % k)
          if k == :user
            obj.user = user
            Dcmgr.logger.debug(" value: %s" % user)
          elsif req_hash[k.to_s]
            if k == :account
              obj.account = Account[req_hash[k.to_s]]
              Dcmgr.logger.debug(" value: %s" % obj.account)
            else
              obj.send('%s=' % k, req_hash[k.to_s])
              Dcmgr.logger.debug(" value: %s" % obj.send(k))
            end
          else
            Dcmgr.logger.debug(" value: undefined")
          end
        }
      else
        obj.set_all(req_hash)
      end

      obj.save
    end
    
    def create
      format_object(_create())
    end

    def update
      obj = model[uuid]
      req_hash = json_request
      obj.set_all(req_hash)
      format_object(obj.save)
    end
    
    def destroy
      obj = model[uuid]
      obj.destroy
    end

    def json_request
      raise "no data" unless request.body.size > 0
      parsed = JSON.parse(request.body.read)
      Dcmgr.logger.debug("request: " + parsed.inspect)
      parsed
    end
    
    def initialize(user, request)
      @user = user
      @request = request
    end

    #def exec(block, id)
    #  self.instance_eval &lambda {block.call(id)}
    #end
  end

  class PublicAccount
    include PublicModel
    model Account

    public_action :get do
      list
    end

    public_action :post do
      account = create
      # create account roll
      AccountRoll.create(:account=>account,:user=>user)
      account
    end

    public_action_withid :delete do
      destroy
    end
  end

  class PublicUser
    include PublicModel
    model User

    public_action :post do
      create
    end
    
    public_action :get, :myself do
      user
    end
    
    #public_action_withid :delete do |id|
    public_action_withid :delete do
      destroy
    end

    public_action_withid :put, :add_tag do
      target = User[uuid]
      tag_uuid = request.GET['tag']
      tag = Tag[tag_uuid]
      Dcmgr.logger.debug(uuid)
      Dcmgr.logger.debug(tag)
      if tag
        TagMapping.create(:tag_id=>tag.id,
                          :target_type=>TagMapping::TYPE_USER,
                          :target_id=>target.id)
      end
    end
  end

  class PublicNameTag
    include PublicModel
    model Tag
    public_name 'name_tags'
    allow_keys [:account, :name]

    public_action :post do
      create
    end
    
    public_action_withid :delete do
      destroy
    end
  end

  class PublicAuthTag
    include PublicModel
    model Tag
    public_name 'auth_tags'
    allow_keys [:account, :name, :tag_type, :roll]

    public_action :post do
      req_hash = json_request
      req_hash.delete 'id'
      tags = req_hash.delete 'tags'

      req_hash['tag_type'] = Tag::TYPE_AUTH
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
      
      format_object(obj)
    end
    
    public_action_withid :delete do
      destroy
    end
  end

  class PublicInstance
    include PublicModel
    model Instance
    allow_keys [:account, :user, :physical_host, :image_storage,
               :need_cpus, :need_cpu_mhz, :need_memory]

    public_action :get do
      list
    end
    
    public_action_withid :get do
      get
    end
    
    public_action_withid :put, :add_tag do
      target = Instance[uuid]
      tag_uuid = request.GET['tag']
      tag = Tag[tag_uuid]
      Dcmgr.logger.debug("")
      Dcmgr.logger.debug(uuid)
      Dcmgr.logger.debug(tag)
      Dcmgr.logger.debug("")
      if tag
        TagMapping.create(:tag_id=>tag.id,
                          :target_type=>TagMapping::TYPE_INSTANCE,
                          :target_id=>target.id)
      end
    end
    
    public_action_withid :put, :remove_tag do
      target = Instance[uuid]
      tag_uuid = request.GET['tag']
      tag = Tag[tag_uuid]
      target.remove_tag(tag.id) if tag
    end
    
    public_action :post do
      req_hash = json_request
      req_hash.delete 'id'
      
      req_hash['image_storage'] = ImageStorage[1]

      obj = _create(req_hash)
      physical_host = HVController.schedule_instance(obj)
      obj.hv_controller = physical_host.add_physical_host
      obj.save
      
      format_object(obj)
    end
    
    public_action_withid :get do
      get
    end
    
    public_action_withid :put do
      update
    end

    public_action_withid :delete do
      destory
    end

    public_action_withid :put, :reboot do
      [] # TODO: reboot action
    end

    public_action_withid :put, :terminate do
      [] # TODO: terminate action
    end

    public_action_withid :put, :run do
      instance = Instance[uuid]
      instance.status = Instance::STATUS_TYPE_RUNNING
      instance.save
      []
    end

    public_action_withid :put, :shutdown do
      instance = Instance[uuid]
      begin
        Dcmgr.execute(user, instance, :shutdown)
      rescue Exception => e
        Dcmgr::logger.debug("err! %s" % e)
        raise e
        throw :halt, [400, e.to_s]
      end
      []
    end

    public_action_withid :put, :snapshot do
      [] # TODO: snapshot action
    end
  end

  class PublicHvController
    include PublicModel
    model HvController

    public_action :post do
      create
    end

    public_action_withid :delete, :destory do
      destroy
    end
  end

  class PublicImageStorage
    include PublicModel
    model ImageStorage

    public_action :get do
      list
    end

    public_action :post do
      create
    end

    public_action_withid :get do
      get
    end

    public_action_withid :delete, :destroy do
      destory
    end
  end

  class PublicImageStorageHost
    include PublicModel
    model ImageStorageHost

    public_action :get do
      list
    end

    public_action :post do
      create
    end

    public_action_withid :get do
      get
    end

    public_action_withid :delete do
      destory
    end
  end

  class PublicPhysicalHost
    include PublicModel
    model PhysicalHost
    
    public_action :get do
      list
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
      user_uuid = request.GET['user']
      relate_user = User[user_uuid]
      target = PhysicalHost[uuid]
      target.relate_user_id = relate_user.id
      target.save
      target
    end
  end
end
