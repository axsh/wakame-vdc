require 'json'

module Dcmgr
  module PublicModel
    module ClassMethods
      def get_actions
        @public_actions.each{|method, path, args, arg_count, action|
          yield [method, path, route(self, action, arg_count)]
        }
      end
      
      def public_action(method, *args, &block)
        @public_actions ||= []
        @public_actions << [method, url_all, args, 0, block]
      end
      
      def public_action_withid(method, name=nil, *args, &block)
        @public_actions ||= []
        @public_actions << [method, url_id(name), args, 1, block]
      end
      
      def url_all
        "/#{public_name}.json"
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
      
      def model_name
        @model.to_s # ex. models
      end
      
      def public_name
        @model.table_name.to_s # Models
      end
      
      def route(public_class, block, args)
        Dcmgr::logger.debug "route: %s, %s, %s, %d" % [self, public_class, block, args]
        proc do |id|
          logger.debug "url: " + request.url
          protected!
          obj = public_class.new(request)
          # ret = obj.exec(block, nil)
          obj.uuid = id if id
          ret = obj.instance_eval(&block)
          # logger.debug "response(inspect): " + ret.inspect
          json_ret = public_class.json_render(ret)
          logger.debug "response(json): " + json_ret
          json_ret
        end
      end
      
      def json_render(obj)
        def model2hash i
          h = Hash[i.keys.collect{ |key| [key, i.send(key)] }]
          
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
    attr_accessor :request
    
    def model
      self.class.model
    end
    
    def list
      model.all
    end
    
    def get
      model.search_by_uuid(uuid)
    end

    def create
      req_hash = json_request
      req_hash.delete 'id'

      obj = model.new
      obj.set_all(req_hash)
      obj.save

      obj
    end

    def update
      obj = model.search_by_uuid(uuid)
      req_hash = json_request
      obj.set_all(req_hash)
      obj.save
    end
    
    def destroy
      obj = model.search_by_uuid(uuid)
      obj.destroy
    end

    def json_request
      raise "no data" unless request.body.size > 0
      parsed = JSON.parse(request.body.read)
      parsed
    end
    
    def initialize(request)
      @request = request
    end

    #def exec(block, id)
    #  self.instance_eval &lambda {block.call(id)}
    #end
  end

  class PublicUser
    include PublicModel
    model User

    public_action :post do
      create
    end
    
    #public_action_withid :delete do |id|
    public_action_withid :delete do
      destroy
    end
  end

  class PublicTag
    include PublicModel
    model Tag

    public_action :post do
      create
    end
    
    #public_action_withid :delete do |id|
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
    
    public_action :post do
      crreate
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

    def list; list; end
    def create; create; end
    def get id; get id; end
    def destroy id; destroy id; end

    def self.public_actions
      [[:get,     pattern_all,    :list, 0],
       [:post,    pattern_all,    :create, 0],
       [:get,     pattern_target, :get, 1],
       [:delete,  pattern_target, :destroy, 1],
      ]
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
