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
    spec = M::InstanceSpec[params[:instance_spec_id]] || raise(E::InvalidInstanceSpec)    
    
    raise "E::UnknownImage" unless lb_conf.config.include? :image_id
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
               'instance_spec_id' => spec.canonical_uuid,
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
  
  put '/:id/register' do
    raise E::Undefined:UndefinedLoadBalancerID if params[:id].nil?  

    lb = find_by_uuid(:LoadBalancer, params[:id])
    raise E::UnknownInstance if lb.nil?
    
    request_vifs = params[:vifs]
    raise E::UnknownNetworkVif if request_vifs.nil?

    request_vifs = request_vifs.each_line.to_a if request_vifs.is_a?(String)
    hold_vifs = lb.load_balancer_targets.collect {|t| t.network_vif_id }
    target_vifs = request_vifs - hold_vifs
    raise(E::DuplicateNetworkVif) if target_vifs.empty? 

    targets = []
    target_vifs.each do |uuid| 
      vif = M::NetworkVif[uuid]
      ip_lease = vif.direct_ip_lease
      next if ip_lease.empty?

      targets << {
        :ipv4 => ip_lease.first.ipv4,
      }

      lb.add_target(vif.canonical_uuid)
      lb.save
    end

    raise E::UnknownNetworkVif if targets.empty?

    EM.defer do
      proxy = Dcmgr::Drivers::Haproxy.new
      proxy.set_mode(haproxy_mode(lb.instance_protocol))
      proxy.set_balance(lb.balance_name)
      proxy.set_cookie_name(lb.cookie_name)
      targets.each do |t|
        proxy.add_server(t[:ipv4], lb.instance_port)
      end

      proxy.bind do 
        EM.schedule do
          conn = Dcmgr.messaging.amqp_client
          channel = AMQP::Channel.new(conn)
          ex = channel.topic(lb.topic_name, lb.queue_options)
          begin 
            channel = AMQP::Channel.new(conn)
            queue = AMQP::Queue.new(channel, lb.queue_name, :exclusive => false, :auto_delete => true)
            queue.bind(ex)
            queue.publish(proxy.config)
          rescue Exception => e
            logger.error(e.message)
          end
        end 
      end

    end
    
    commit_transaction
    respond_with(R::LoadBalancer.new(lb).generate)
  end

  put '/:id/unregister' do
    #pending
  end

  put '/:id/enable' do
    #pending
  end

  put '/:id/disable' do
    #pending
  end
  
  put '/:id' do
    #pending
  end

  delete '/:id' do
    #pending
  end
  
  private
  def haproxy_mode(protocol) 
    case protocol
      when 'tcp', 'ssl'
        'tcp'
      when 'http', 'https'
        'http'
    end
  end

end
