# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/load_balancer'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/load_balancers' do

  get do
    ds = M::LoadBalancer.dataset

    if params[:account_id]
      ds = ds.filter(:account_id=>params[:account_id])
    end

    ds = datetime_range_params_filter(:created, ds)
    ds = datetime_range_params_filter(:terminated, ds)

    collection_respond_with(ds) do |paging_ds|
      R::LoadBalancerCollection.new(paging_ds).generate
    end
  end

  post do

    # copy request params
    lb_conf = Dcmgr.conf.service_types['lb']
     
    raise "E::UnknownImage" unless lb_conf.config.include? :image_id
    raise "E::UnknownInstanceSpec" unless lb_conf.config.include? :instance_spec_id
    raise "E::UnknownHostNode" unless lb_conf.config.include? :host_node_id
    raise "E::UnknownSecurityGroup" unless lb_conf.config.include? :security_group
    raise "E::UnknownSshKeyPair" unless lb_conf.config.include? :ssh_key_id

    origin_env = {}
    env_keys = ['rack.request.form_vars',
                'rack.request.form_hash',
                'REQUEST_PATH',
                'PATH_INFO',
                'REQUEST_URI'
                ]

    # copy env
    env_keys.each { |key| origin_env[key] = env[key] } 
  
    # make params for internal request.
    values  = {'image_id' => lb_conf.image_id,
               'instance_spec_id' => lb_conf.instance_spec_id,
               'host_node_id' => lb_conf.host_node_id,
               'security_group' => lb_conf.security_group,
               'ssh_key_id' => lb_conf.ssh_key_id
    } 

    # TODO: Using sinatra plugin.
    env['rack.request.form_vars'] = values.collect { |k,v| "#{k}=#{v}" }.join('&') 
    env['rack.request.form_hash'] = ::Rack::Utils.parse_query(env['rack.request.form_vars'])
    env['REQUEST_PATH'] = '/api/12.03/instances.json'
    env['PATH_INFO'] = '/instances'
    env['REQUEST_URI'] = '/api/12.03/instances.json'
    
    # Create Instance
    http_status, headers, body = self.dup.call(env)

    # undo env
    env_keys.each { |key| env[key] = origin_env[key] }
    
    # create load balancer
    b = ::JSON.load(body.shift)

    i = find_by_uuid(:Instance, b['id'])
    lb = M::LoadBalancer.create(:account_id => @account.canonical_uuid,
                                :description => params[:description],
                                :instance_id => i.id,
                                )
     
    respond_with(R::LoadBalancer.new(lb).generate)
  end
end
