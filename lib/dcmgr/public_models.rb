require 'json'

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
          ret = obj.instance_eval(&block)
          logger.debug "response(inspect): " + ret.inspect
          json_ret = public_class.json_render(ret)
          logger.debug "response(json): " + json_ret
          json_ret
        end
      end
      
      def json_render(obj)
        def model2hash i
          list = i.keys.collect{ |key| [key, i.send(key)] }
          h = Hash[*list.flatten]
          
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

    def format_object(obj)
      obj
    end
    
    def list
      model.all.map{|o| format_object(o)}
    end
    
    def get
      format_object(model.search_by_uuid(uuid))
    end

    def create
      req_hash = json_request
      req_hash.delete 'id'

      obj = model.new
      obj.set_all(req_hash)
      format_object(obj.save)
    end

    def update
      obj = model.search_by_uuid(uuid)
      req_hash = json_request
      obj.set_all(req_hash)
      format_object(obj.save)
    end
    
    def destroy
      obj = model.search_by_uuid(uuid)
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

    public_action :post do
      create
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
      target = User.search_by_uuid(uuid)
      tag_uuid = request.GET['tag']
      tag = Tag.search_by_uuid(tag_uuid)
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

    public_action :post do
      req_hash = json_request
      req_hash.delete 'id'

      obj = model.new
      
      tags = req_hash.delete 'tags'
      
      req_hash['tag_type'] = Tag::TYPE_AUTH
      
      obj.set_all(req_hash)
      obj.save
      
      # tag mappings
      Dcmgr.logger.debug("tags")      
      Dcmgr.logger.debug(tags)
      tags.each {|tag_uuid|
        tag = Tag.search_by_uuid(tag_uuid)
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

  class PublicInstance
    include PublicModel
    model Instance

    public_action :get do
      list
    end
    
    public_action_withid :get do
      get
    end
    
    public_action_withid :put, :add_tag do
      target = Instance.search_by_uuid(uuid)
      tag_uuid = request.GET['tag']
      tag = Tag.search_by_uuid(tag_uuid)
      Dcmgr.logger.debug(uuid)
      Dcmgr.logger.debug(tag)
      if tag
        TagMapping.create(:tag_id=>tag.id,
                          :target_type=>TagMapping::TYPE_INSTANCE,
                          :target_id=>target.id)
      end
    end
    
    public_action :post do
      create
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

    public_action_withid :put, :shutdown do
      instance = Instance.search_by_uuid(uuid)
      Dcmgr::logger.debug "instance: %s" % instance.uuid
      Dcmgr::logger.debug "instance.tags:"
      instance.tags.each{|tag|
        Dcmgr::logger.debug "  %s" % tag.uuid
      }
      if instance.tags.length <= 0
        throw :halt, [400, 'err']
      end
      []
    end

    public_action_withid :put, :snapshot do
      [] # TODO: snapshot action
    end

    def format_object(object)
      if object
        object.keys.push :tags
      end
      object
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
      delete
    end

    public_action_withid :put, :relate do
      user_id = request.GET[:user].to_i
      obj = model.find(:id=>id.to_i)

      obj.relate_user_id = request.GET['user'].to_i
      obj.save
      obj
    end
  end
end
