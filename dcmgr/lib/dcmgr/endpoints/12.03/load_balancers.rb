# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/load_balancer'
require 'sinatra/internal_request'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/load_balancers' do
  LOAD_BALANCER_META_STATE = ['alive', 'alive_with_deleted'].freeze
  LOAD_BALANCER_STATE=['running', 'terminated'].freeze
  LOAD_BALANCER_STATE_ALL=(LOAD_BALANCER_STATE + LOAD_BALANCER_META_STATE).freeze

  register Sinatra::InternalRequest
  register Sinatra::PublishMessage

  PUBLIC_DEVICE_INDEX = 0
  MANAGEMENT_DEVICE_INDEX = 1

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
    lb_port = params[:port].to_i

    raise E::InvalidLoadBalancerPort unless lb_port >= 1 && lb_port <= 65535

    amqp_settings = AMQP::Client.parse_connection_uri(lb_conf.amqp_server_uri)

    user_data = []
    user_data << "AMQP_SERVER=#{amqp_settings[:host]}"
    user_data << "AMQP_PORT=#{amqp_settings[:port]}"

    security_group_rules = []
    security_group_rules << 'icmp:-1,-1,ip4:0.0.0.0'
    security_group_rules << "tcp:#{lb_port},#{lb_port},ip4:0.0.0.0"

    instance_security_group = create_security_group(security_group_rules)

    # make params for internal request.
    request_params = {'image_id' => lb_conf.image_id,
                      'instance_spec_id' => spec.canonical_uuid,
                      'host_node_id' => lb_conf.host_node_id,
                      'ssh_key_id' => lb_conf.ssh_key_id,
                      'service_type' => lb_conf.name,
                      'user_data' => user_data.join("\n"),
                      'vifs' => [{'index' => PUBLIC_DEVICE_INDEX.to_s,
                                  'network' => lb_conf.instances_network,
                                  'security_groups' => instance_security_group
                                 },{
                                  'index' => MANAGEMENT_DEVICE_INDEX.to_s,
                                  'network' => lb_conf.management_network,
                                  'security_groups' => ''
                      }]
    }

    http_status, headers, body = internal_request("/api/12.03/instances.json", request_params, {
      'PATH_INFO' => '/instances',
    })

    i = find_by_uuid(:Instance, body['id'])
    lb = M::LoadBalancer.create(:account_id => @account.canonical_uuid,
                                :description => params[:description],
                                :instance_id => i.id,
                                :balance_name => params[:balace_name] || 'leastconn',
                                :protocol => params[:protocol] || 'http',
                                :port => params[:port] || 80,
                                :instance_protocol => params[:instance_protocol] || 'http',
                                :instance_port => params[:instance_port] || 80,
                                :display_name => params[:display_name],
                                :cookie_name => params[:cookie_name],
                                :private_key => params[:private_key],
                                :public_key => params[:public_key],
                                :certificate_chain => params[:certificate_chain]
                                )


    config_params = {
      :instance_protocol => lb.instance_protocol,
      :instance_port => lb.instance_port,
      :port => lb.connect_port,
      :protocol => lb.protocol,
      :balance_name => lb.balance_name,
      :cookie_name => lb.cookie_name,
      :ipset => []
    }

    queue_params = {
      :topic_name => lb.topic_name,
      :queue_options => lb.queue_options,
      :queue_name => lb.queue_name,
    }

    on_after_commit do
      if lb.is_secure?
        update_ssl_proxy_config({
          :accept_port => lb.accept_port,
          :connect_port => lb.connect_port,
          :protocol => lb.protocol,
          :private_key => lb.private_key,
          :public_key => lb.public_key
        }.merge(queue_params))
      end
      update_load_balancer_config(config_params.merge(queue_params))
    end
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
      :port => lb.connect_port,
      :protocol => lb.protocol,
      :balance_name => lb.balance_name,
      :cookie_name => lb.cookie_name,
      :ipset => []
    }

    queue_params = {
      :topic_name => lb.topic_name,
      :queue_options => lb.queue_options,
      :queue_name => lb.queue_name,
    }

    lb_network_vif = lb.network_vifs(PUBLIC_DEVICE_INDEX)
    lb_security_groups = lb_network_vif.security_groups.collect{|sg| sg.canonical_uuid }

    targets = []
    target_vifs.each do |uuid|
      vif = M::NetworkVif[uuid]
      ip_lease = vif.direct_ip_lease
      next if ip_lease.empty?

      config_params[:ipset] << {
        :ipv4 => ip_lease.first.ipv4,
      }

      # register instance to load balancer.
      lb.add_target(uuid)
      lb.save

      # update security groups to registered instance.
      i_security_groups = vif.security_groups.collect{|sg| sg.canonical_uuid }
      request_params = {
        :id => vif.instance.canonical_uuid,
        :security_groups => lb_security_groups + i_security_groups
      }
      update_security_groups(request_params)
    end

    raise E::UnknownNetworkVif if config_params[:ipset].empty?

    on_after_commit do
     update_load_balancer_config(config_params.merge(queue_params))
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

    lb_network_vif = lb.network_vifs(PUBLIC_DEVICE_INDEX)
    lb_security_groups = lb_network_vif.security_groups.collect{|sg| sg.canonical_uuid }
    remove_vifs = request_vifs & hold_vifs
    remove_vifs.each do |uuid|
     lb.remove_target(uuid)
     lb.save

     # update security groups to registered instance.
     vif = find_by_uuid(:NetworkVif, uuid)
     i_security_groups = vif.security_groups.collect{|sg| sg.canonical_uuid }
     request_params = {
       :id => vif.instance.canonical_uuid,
       :security_groups => i_security_groups - lb_security_groups
     }
     update_security_groups(request_params)

    end

    config_params = {
      :instance_protocol => lb.instance_protocol,
      :instance_port => lb.instance_port,
      :balance_name => lb.balance_name,
      :cookie_name => lb.cookie_name,
      :port => lb.connect_port,
      :protocol => lb.protocol,
      :ipset => []
    }

    queue_params = {
      :topic_name => lb.topic_name,
      :queue_options => lb.queue_options,
      :queue_name => lb.queue_name
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
      update_load_balancer_config(config_params.merge(queue_params))
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

    http_status, headers, body = internal_request("/api/12.03/instances.json", {}, {
      'REQUEST_PATH' => "/api/12.03/instances/#{lb_i.canonical_uuid}.json",
      'PATH_INFO' => "/instances/#{lb_i.canonical_uuid}.json",
      'REQUEST_URI' => "/api/12.03/instances/#{lb_i.canonical_uuid}.json"
    })

    if body.include? lb_i.canonical_uuid
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

  def update_ssl_proxy_config(values)
    s = Dcmgr::Drivers::Stunnel.new
    s.accept_port = values[:accept_port]
    s.connect_port = values[:connect_port]
    s.protocol = values[:protocol]
    stunnel_config = s.bind_template('stunnel.cnf')
    queue_params = {
      :topic_name => values[:topic_name],
      :queue_options => values[:queue_options],
      :queue_name => values[:queue_name]
    }
    publish(values[:private_key], queue_params.merge({:name => 'private_key'}))
    publish(values[:public_key], queue_params.merge({:name => 'public_key'}))
    publish(stunnel_config, queue_params.merge({:name => 'stunnel'}))
  end

  def update_load_balancer_config(values)
    proxy = Dcmgr::Drivers::Haproxy.new(Dcmgr::Drivers::Haproxy.mode(values[:protocol]))
    proxy.set_balance(values[:balance_name])
    proxy.set_cookie_name(values[:cookie_name]) unless values[:cookie_name].empty?
    proxy.set_bind('*', values[:port])

    if !values[:ipset].empty?
      values[:ipset].each do |t|
        proxy.add_server(t[:ipv4], values[:instance_port])
      end
    end

    haproxy_config = proxy.bind_template(proxy.template_file_path)
    publish(haproxy_config, {
      :name => 'haproxy',
      :topic_name => values[:topic_name],
      :queue_options => values[:queue_options],
      :queue_name => values[:queue_name]
    })
  end

  def create_security_group(rules)
   http_status, headers, body = internal_request("/api/12.03/security_groups.json",{
      'account_id' => @account.canonical_uuid,
      'rule' => rules.join("\n"),
      'service_type' => 'lb',
      'description' => '',
      'display_name' => ''
    }, {
      'PATH_INFO' => '/security_groups',
    })
    body['uuid']
  end

  def update_security_groups(params)
    path = "/instances/#{params[:id]}"
    uri = "/api/12.03/#{path}.json"
    http_status, headers, body = internal_request(uri,{
      'security_groups' => params[:security_groups]
    }, {
      'PATH_INFO' => "#{path}",
      'REQUEST_METHOD' => 'PUT',
      'REQUEST_URI' => uri,
      'REQUEST_PATH' => uri
    })
    body
  end

end
