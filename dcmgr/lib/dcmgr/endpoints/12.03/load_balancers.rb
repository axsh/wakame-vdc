# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/load_balancer'
require 'amqp'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/load_balancers' do
  LOAD_BALANCER_META_STATE = ['alive', 'alive_with_deleted'].freeze
  LOAD_BALANCER_STATE=['running', 'terminated'].freeze
  LOAD_BALANCER_STATE_ALL=(LOAD_BALANCER_STATE + LOAD_BALANCER_META_STATE).freeze

  get do
    ds = M::LoadBalancer.dataset

    if params[:state]
      ds = if LOAD_BALANCER_META_STATE.member?(params[:state])
             case params[:state]
             when 'alive'
               ds.lives
             when 'alive_with_deleted'
               ds.alives_and_deleted
             else
               raise E::InvalidParameter, :state
             end
           elsif LOAD_BALANCER_STATE.member?(params[:state])
             ds.by_state(params[:state])
           else
             raise E::InvalidParameter, :state
           end
    end

    if params[:account_id]
      ds = ds.filter(:account_id=>params[:account_id])
    end

    ds = datetime_range_params_filter(:created, ds)
    ds = datetime_range_params_filter(:deleted, ds)

    collection_respond_with(ds) do |paging_ds|
      R::LoadBalancerCollection.new(paging_ds).generate
    end
  end

  get '/:id' do
    lb = find_by_uuid(:LoadBalancer, params[:id])
    raise E::UnknownLoadBalancer, params[:id] if lb.nil?

    respond_with(R::LoadBalancer.new(lb).generate)
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
               'ssh_key_id' => lb_conf.ssh_key_id,
               'service_type' => lb_conf.name,
               'user_data' => user_data.join("\n")
    }

    # TODO: Using sinatra plugin.
    _req = ::Rack::Request.new \
      ::Rack::MockRequest.env_for("/api/12.03/instances.json",
      :params => values)

    _req.env['PATH_INFO'] = '/instances'
    _req.env['SERVER_NAME'] = env['SERVER_NAME']
    _req.env['SERVER_PORT'] = env['SERVER_PORT']
    _req.env['CONTENT_TYPE'] = 'application/json'
    _req.env['REQUEST_METHOD'] = env['REQUEST_METHOD']
    _req.env['HTTP_X_VDC_ACCOUNT_UUID'] = env['HTTP_X_VDC_ACCOUNT_UUID']

    http_status, headers, body = self.dup.call(_req.env)

    # create load balancer
    b = ::JSON.load(body.shift)

    i = find_by_uuid(:Instance, b['id'])
    lb = M::LoadBalancer.create(:account_id => @account.canonical_uuid,
                                :description => params[:description],
                                :instance_id => i.id,
                                :balance_name => params[:balace_name] || 'leastconn',
                                :protocol => params[:protocol] || 'http',
                                :port => params[:port] || 80,
                                :instance_protocol => params[:instance_protocol] || 'http',
                                :instance_port => params[:instance_port] || 80,
                                :display_name => params[:display_name],
                                :cookie_name => params[:cookie_name]
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

    config_params = {
      :instance_protocol => lb.instance_protocol,
      :instance_port => lb.instance_port,
      :balance_name => lb.balance_name,
      :cookie_name => lb.cookie_name,
      :topic_name => lb.topic_name,
      :queue_options => lb.queue_options,
      :queue_name => lb.queue_name,
      :ipset => []
    }

    targets = []
    target_vifs.each do |uuid|
      vif = M::NetworkVif[uuid]
      ip_lease = vif.direct_ip_lease
      next if ip_lease.empty?

      config_params[:ipset] << {
        :ipv4 => ip_lease.first.ipv4,
      }

      lb.add_target(uuid)
      lb.save
    end

    raise E::UnknownNetworkVif if config_params[:ipset].empty?
    on_after_commit do
      update_load_balancer_config(config_params)
    end
    respond_with(R::LoadBalancer.new(lb).generate)
  end

  put '/:id/unregister' do
    raise E::Undefined:UndefinedLoadBalancerID if params[:id].nil?

    lb = find_by_uuid(:LoadBalancer, params[:id])
    raise E::UnknownInstance if lb.nil?

    request_vifs = params[:vifs]
    raise E::UnknownNetworkVif if request_vifs.nil?

    request_vifs = request_vifs.each_line.to_a if request_vifs.is_a?(String)
    hold_vifs = lb.load_balancer_targets.collect {|t| t.network_vif_id }
    raise E::UnknownNetworkVif if hold_vifs.empty?
    remove_vifs = request_vifs & hold_vifs
    remove_vifs.each do |uuid|
     lb.remove_target(uuid)
     lb.save
    end

    config_params = {
      :instance_protocol => lb.instance_protocol,
      :instance_port => lb.instance_port,
      :balance_name => lb.balance_name,
      :cookie_name => lb.cookie_name,
      :topic_name => lb.topic_name,
      :queue_options => lb.queue_options,
      :queue_name => lb.queue_name,
      :ipset => []
    }

    targets = []
    target_vifs = hold_vifs - request_vifs
    target_vifs.each do |uuid|
      vif = M::NetworkVif[uuid]
      ip_lease = vif.direct_ip_lease
      next if ip_lease.empty?

      config_params[:ipset] << {
        :ipv4 => ip_lease.first.ipv4,
      }
    end

    on_after_commit do
      update_load_balancer_config(config_params)
    end
    respond_with(R::LoadBalancer.new(lb).generate)
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
    lb = find_by_uuid(:LoadBalancer, params[:id])
    raise E::UnknownInstance if lb.nil?

    raise E::ExistsRegisteredInstance unless lb.load_balancer_targets.empty?

    lb_i = lb.instance

    # TODO: Using sinatra plugin.
    env['REQUEST_PATH'] = "/api/12.03/instances/#{lb_i.canonical_uuid}.json"
    env['PATH_INFO'] = "/instances/#{lb_i.canonical_uuid}.json"
    env['REQUEST_URI'] = "/api/12.03/instances/#{lb_i.canonical_uuid}.json"

    # Create Instance
    http_status, headers, body = self.dup.call(env)

    # create load balancer
    b = ::JSON.load(body.shift)

    if b.include? lb_i.canonical_uuid
      lb.destroy
    else
      raise E::InvalidLoadBalancerState, lb.state
    end

    respond_with(R::LoadBalancer.new(lb).generate)
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

  def update_load_balancer_config(params)
    EM.defer do
      proxy = Dcmgr::Drivers::Haproxy.new
      proxy.set_mode(haproxy_mode(params[:instance_protocol]))
      proxy.set_balance(params[:balance_name])
      proxy.set_cookie_name(params[:cookie_name])
      params[:ipset].each do |t|
        proxy.add_server(t[:ipv4], params[:instance_port])
      end

      proxy.bind do
        EM.schedule do
          conn = Dcmgr.messaging.amqp_client
          channel = AMQP::Channel.new(conn)
          ex = channel.topic(params[:topic_name], params[:queue_options])
          begin
            channel = AMQP::Channel.new(conn)
            queue = AMQP::Queue.new(channel, params[:queue_name], :exclusive => false, :auto_delete => true)
            queue.bind(ex)
            queue.publish(proxy.config)
          rescue Exception => e
            logger.error(e.message)
          end
        end
      end

    end

  end
end
    amqp_settings = AMQP::Client.parse_connection_uri(lb_conf.amqp_server_uri)
    user_data = []
    user_data << "AMQP_SERVER=#{amqp_settings[:host]}"
    user_data << "AMQP_PORT=#{amqp_settings[:port]}"
