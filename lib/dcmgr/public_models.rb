require 'json'

def json_render(obj)
  def obj2hash i
    Hash[i.keys.collect{ |key| [key, i[key]] }]
  end
  
  if obj.is_a? Array
    ret = obj.collect{|i| obj2hash(i)}
    ret.to_json
  else
    ret = obj2hash(obj)
    ret.to_json
  end
end

module PublicModelModule
  def pattern_all
    "/#{public_name}.json"
  end

  def pattern_target(action=nil)
    unless action
      %r{/#{public_name}/(\d+).json}
    else
      %r{/#{public_name}/(\d+)/#{action}.json}
    end
  end
  
  def model
    raise "not implemented model"
  end

  def model_name
    model.to_s # ex. models
  end

  def public_name
    model.table_name.to_s # Models
  end
  
  def get_action(public_class, actiontag, args)
    if args == 0
      act = proc do
        puts "url: " + request.url
        protected!
        obj = public_class.new(request)
        ret = eval("obj.#{actiontag}")
        puts "response: " + ret.inspect
        json_ret = json_render(ret)
        puts "response: " + json_ret
        json_ret
      end
    else
      act = proc do |id|
        puts "url: " + request.url
        protected!
        obj = public_class.new(request)
        ret = eval("obj.#{actiontag} id")
        puts "response: " + ret.inspect
        json_ret = json_render(ret)
        puts "response: " + json_ret
        json_ret
      end
    end
    act
  end
end

class PublicModel
  extend PublicModelModule

  def model
    self.class.model
  end
  
  def default_list
   model.all
  end
  
  def default_get(id)
    model.find(:id=>id.to_i)
  end

  def default_create
    req_hash = json_request
    req_hash.delete 'id'

    obj = model.new
    obj.set_all(req_hash)
    obj.save

    obj = model[obj.id]
  end

  def default_update(id)
    obj = model.find(:id=>id.to_i)
    req_hash = json_request
    obj.set_all(req_hash)
    obj.save
  end
  
  def default_destroy(id)
    obj = model.find(:id=>id.to_i)
    obj.destroy
  end

  def json_request
    raise "no data" unless request.body.size > 0
    parsed = JSON.parse(request.body.read)
    puts "request: " + parsed.inspect
    parsed
  end
  
  def initialize(request)
    @request = request
  end
  
  attr_accessor :request
end

class PublicInstance < PublicModel
  def self.model
    Instance
  end

  def list
    default_list
  end

  def create; default_create; end
  
  def get id; default_get id; end
  def update id; default_update id; end
  def destroy id; default_destroy id; end

  def reboot id
    # TODO: reboot action
    []
  end

  def terminate id
    # TODO: terminate action
    []
  end

  def snapshot id
    # TODO: snapshot action
    []
  end

  def self.public_actions
    [[:get,     pattern_all,    :list, 0],
     [:post,    pattern_all,    :create, 0],
     [:get,     pattern_target, :get, 1],
     [:put,     pattern_target, :update, 1],
     [:delete,  pattern_target, :destroy, 1],

     # actions
     [:put,     pattern_target(:reboot),    :reboot, 1],
     [:put,     pattern_target(:terminate), :terminate, 1],
     [:put,     pattern_target(:snapshot),  :snapshot, 1],
    ]
  end
end

class PublicGroup < PublicModel
  def self.model
    Group
  end

  def create; default_create; end
  def destroy id; default_destroy id; end

  def self.public_actions
    [[:post,    pattern_all,    :create, 0],
     [:delete,  pattern_target, :destroy, 1],
    ]
  end
end

class PublicUser < PublicModel
  def self.model
    User
  end

  def create; default_create; end
  def destroy id; default_destroy id; end

  def self.public_actions
    [[:post,    pattern_all,    :create, 0],
     [:delete,  pattern_target, :destroy, 1],
    ]
  end
end

class PublicHvController < PublicModel
  def self.model
    HvController
  end

  def create; default_create; end
  def destroy id; default_destroy id; end

  def self.public_actions
    [[:post,    pattern_all,    :create, 0],
     [:delete,  pattern_target, :destroy, 1],
    ]
  end
end

class PublicImageStorage < PublicModel
  def self.model
    ImageStorage
  end

  def list; default_list; end
  def create; default_create; end
  def get id; default_get id; end
  def destroy id; default_destroy id; end

  def self.public_actions
    [[:get,     pattern_all,    :list, 0],
     [:post,    pattern_all,    :create, 0],
     [:get,     pattern_target, :get, 1],
     [:delete,  pattern_target, :destroy, 1],
    ]
  end
end

class PublicImageStorageHost < PublicModel
  def self.model
    ImageStorageHost
  end

  def list; default_list; end
  def create; default_create; end
  def get id; default_get id; end
  def destroy id; default_destroy id; end

  def self.public_actions
    [[:get,     pattern_all,    :list, 0],
     [:post,    pattern_all,    :create, 0],
     [:get,     pattern_target, :get, 1],
     [:delete,  pattern_target, :destroy, 1],
    ]
  end
end

class PublicPhysicalHost < PublicModel
  def self.model
    PhysicalHost
  end

  def list; default_list; end
  def create; default_create; end
  def get id; default_get id; end
  def destroy id; default_destroy id; end

  def relate id
    user_id = request.GET[:user].to_i
    obj = model.find(:id=>id.to_i)

    obj.relate_user_id = request.GET['user'].to_i
    obj.save
    obj
  end

  def self.public_actions
    [[:get,     pattern_all,    :list, 0],
     [:post,    pattern_all,    :create, 0],
     [:get,     pattern_target, :get, 1],
     [:delete,  pattern_target, :destroy, 1],
     [:put,  pattern_target(:relate), :relate, 1],
    ]
  end
end

