# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/load_balancer'
require 'sinatra/internal_request'
require 'amqp'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/load_balancers' do
  LOAD_BALANCER_META_STATE = ['alive', 'alive_with_deleted'].freeze
  LOAD_BALANCER_STATE=['running', 'terminated'].freeze
  LOAD_BALANCER_STATE_ALL=(LOAD_BALANCER_STATE + LOAD_BALANCER_META_STATE).freeze

  register Sinatra::InternalRequest

  PUBLIC_DEVICE_INDEX = 0
  MANAGEMENT_DEVICE_INDEX = 1
  SERVICE_TYPE = 'lb'

  get do
    ds = M::LoadBalancer.dataset

    if params[:state]
      ds = case params[:state]
           when *LOAD_BALANCER_META_STATE
             case params[:state]
             when 'alive'
               ds.lives
             when 'alive_with_deleted'
               ds.alives_and_deleted
             else
               raise E::InvalidParameter, :state
             end
           when *LOAD_BALANCER_STATE
             ds.by_state(params[:state])
           else
             raise E::InvalidParameter, :state
           end
    end

    if params[:id]
      uuid = params[:id].split("lb-")[1]
      uuid = params[:id] if uuid.nil?
      ds = ds.filter(:uuid.like("#{uuid}%"))
    end

    if params[:account_id]
      ds = ds.filter(:load_balancers__account_id=>params[:account_id])
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

  quota 'load_balancer.count'
  post do
    lb_conf = Dcmgr.conf.service_types['lb']
    lb_port = params[:port].to_i
    raise E::InvalidLoadBalancerAlgorithm unless ['leastconn', 'source'].include? params[:balance_algorithm]
    raise E::InvalidLoadBalancerPort unless lb_port >= 1 && lb_port <= 65535

    lb = M::LoadBalancer.new
    lb.account_id = @account.canonical_uuid
    lb.port = lb_port || 80
    lb.protocol = params[:protocol] || 'http'
    lb.instance_port = params[:instance_port].to_i || 80
    lb.instance_protocol = params[:instance_protocol] || 'http'
    lb.balance_algorithm = params[:balance_algorithm] || 'leastconn'

    if params[:description]
      lb.description = params[:description]
    end

    if params[:display_name]
      lb.display_name = params[:display_name]
    end

    if params[:cookie_name]
      lb.cookie_name = params[:cookie_name]
    end

    if lb.is_secure?
      raise E::InvalidLoadBalancerPublicKey if params[:public_key].nil?
      raise E::InvalidLoadBalancerPrivateKey if params[:private_key].nil?

      lb.public_key = params[:public_key]
      lb.private_key = params[:private_key]
      raise E::EncryptionAlgorithmNotSupported if !lb.check_encryption_algorithm
      raise E::InvalidLoadBalancerPublicKey if !lb.check_public_key
      raise E::InvalidLoadBalancerPrivateKey if !lb.check_private_key
    end

    amqp_settings = AMQP::Client.parse_connection_uri(lb_conf.amqp_server_uri)

    user_data = []
    user_data << "AMQP_SERVER=#{amqp_settings[:host]}"
    user_data << "AMQP_PORT=#{amqp_settings[:port]}"

    security_group_rules = []
    security_group_rules << 'icmp:-1,-1,ip4:0.0.0.0'
    security_group_rules << "tcp:#{lb_port},#{lb_port},ip4:0.0.0.0"

    instance_security_group = create_security_group(security_group_rules)

    lb_spec = Dcmgr::SpecConvertor::LoadBalancer.new
    lb_spec.convert(params[:engine], params[:max_connection])

    # make params for internal request.
    request_params = {'image_id' => lb_conf.image_id,
                      'ssh_key_id' => lb_conf.ssh_key_id,
                      'service_type' => lb_conf.name,
                      'user_data' => user_data.join("\n"),
                      'vifs' => {
                        'eth0' => {
                          'index' => PUBLIC_DEVICE_INDEX.to_s,
                          'network' => lb_conf.instances_network,
                          'security_groups' => instance_security_group
                        },
                        'eth1' =>{
                          'index' => MANAGEMENT_DEVICE_INDEX.to_s,
                          'network' => lb_conf.management_network,
                          'security_groups' => ''
                        }
                      },
                      :hypervisor => lb_spec.hypervisor,
                      :cpu_cores => lb_spec.cpu_cores,
                      :memory_size => lb_spec.memory_size,
                      :quota_weight => lb_spec.quota_weight
    }

    account_uuid = @account.canonical_uuid
    res = request_forward do
      header('X-VDC-Account-UUID', account_uuid)
      post("/instances", request_params)
    end.last_response
    body = JSON.parse(res.body)

    i = find_by_uuid(:Instance, body['id'])

    lb.instance_id = i.id
    lb.save

    config_params = {
      :name => 'start:haproxy',
      :instance_protocol => lb.instance_protocol,
      :instance_port => lb.instance_port,
      :port => lb.connect_port,
      :protocol => lb.protocol,
      :balance_algorithm => lb.balance_algorithm,
      :cookie_name => lb.cookie_name,
      :servers => []
    }

    queue_params = {
      :topic_name => lb.topic_name,
      :queue_options => lb.queue_options,
      :queue_name => lb.queue_name,
    }

    on_after_commit do
      if lb.is_secure?
        Dcmgr::Messaging::LoadBalancer.update_ssl_proxy_config({
          :name => 'start:stud',
          :accept_port => lb.accept_port,
          :connect_port => lb.connect_port,
          :protocol => lb.protocol,
          :private_key => lb.private_key,
          :public_key => lb.public_key
        }.merge(queue_params))
      end
      Dcmgr::Messaging::LoadBalancer.update_load_balancer_config(config_params.merge(queue_params))
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
      :balance_algorithm => lb.balance_algorithm,
      :cookie_name => lb.cookie_name,
      :servers => []
    }

    queue_params = {
      :name => 'reload:haproxy',
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

      # register instance to load balancer.
      lb.add_target(uuid)
      lb_security_groups.each { |lb_inst_secg_id|
        set_vif_sg(:add,uuid,lb_inst_secg_id)
      }
    end

    config_vifs = (request_vifs + hold_vifs).uniq
    config_vifs.each do |uuid|
      ip_lease = M::NetworkVif[uuid].direct_ip_lease
      next if ip_lease.empty?
      config_params[:servers] << {
        :ipv4 => ip_lease.first.ipv4,
      }
    end

    raise E::UnknownNetworkVif if config_params[:servers].length == 0

    on_after_commit do
     Dcmgr::Messaging::LoadBalancer.update_load_balancer_config(config_params.merge(queue_params))
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

    # remove load balancer targets
    remove_vifs = request_vifs & hold_vifs
    lb.remove_targets(remove_vifs)

    # update security groups to registered instance.
    lb_network_vif = lb.network_vifs(PUBLIC_DEVICE_INDEX)
    lb_security_groups = lb_network_vif.security_groups.collect{|sg| sg.canonical_uuid }

    remove_vifs.each do |vif_uuid|
      lb_security_groups.each {|lb_secg_uuid|
      set_vif_sg(:remove,vif_uuid,lb_secg_uuid)
    }
    end

    # update conifg in load balancer image.
    config_params = {
      :instance_protocol => lb.instance_protocol,
      :instance_port => lb.instance_port,
      :balance_algorithm => lb.balance_algorithm,
      :cookie_name => lb.cookie_name,
      :port => lb.connect_port,
      :protocol => lb.protocol,
      :servers => []
    }

    queue_params = {
      :name => 'reload:haproxy',
      :topic_name => lb.topic_name,
      :queue_options => lb.queue_options,
      :queue_name => lb.queue_name
    }

    target_vifs = hold_vifs - request_vifs
    target_vifs.each do |uuid|
      vif = M::NetworkVif[uuid]
      ip_lease = vif.direct_ip_lease
      next if ip_lease.empty?

      config_params[:servers] << {
        :ipv4 => ip_lease.first.ipv4,
      }
    end

    on_after_commit do
      Dcmgr::Messaging::LoadBalancer.update_load_balancer_config(config_params.merge(queue_params))
    end
    respond_with(R::LoadBalancer.new(lb).generate)
  end

  put '/:id' do

    raise E::Undefined:UndefinedLoadBalancerID if params[:id].nil?
    lb = find_by_uuid(:LoadBalancer, params['id'])
    i = lb.instance
    servers = []

    if !params[:balance_algorithm].empty?
      raise E::InvalidLoadBalancerAlgorithm unless ['leastconn', 'source'].include? params[:balance_algorithm]
      lb.balance_algorithm = params[:balance_algorithm]
    end

    if !params[:port].empty?
      lb_port = params[:port].to_i
      raise E::InvalidLoadBalancerPort unless lb_port >= 1 && lb_port <= 65535
      security_group_rules = []
      security_group_rules << 'icmp:-1,-1,ip4:0.0.0.0'
      security_group_rules << "tcp:#{lb_port},#{lb_port},ip4:0.0.0.0"

      request_forward.put("/security_groups/#{lb.network_vifs(PUBLIC_DEVICE_INDEX).security_groups.first.canonical_uuid}", {
       :rule => security_group_rules.join("\n")
      })
      lb.port = params[:port]
    end

    if !params[:protocol].empty?
      lb.protocol = params[:protocol]
    end

    if !params[:instance_protocol].empty?
      lb.instance_protocol = params[:instance_protocol]
    end

    if !params[:instance_port].empty?
      lb.instance_port = params[:instance_port]
    end

    raise E::InvalidLoadBalancerPublicKey if params[:public_key].nil?
    raise E::InvalidLoadBalancerPrivateKey if params[:private_key].nil?

    if lb.is_secure?
      lb.public_key = params[:public_key]
      lb.private_key = params[:private_key]
      raise E::EncryptionAlgorithmNotSupported if !lb.check_encryption_algorithm
      raise E::InvalidLoadBalancerPublicKey if !lb.check_public_key
      raise E::InvalidLoadBalancerPrivateKey if !lb.check_private_key
    end

    if params[:target_vifs] && !params[:target_vifs].empty?
       params[:target_vifs].each {|tv|
        lt = lb.target_network(tv['network_vif_id'])
        lt.fallback_mode = tv['fallback_mode']
        lt.save
        servers << {
          :ipv4 => M::NetworkVif[tv['network_vif_id']].ip.first.ipv4,
          :backup => backup(tv['fallback_mode'])
        }
      }
    else
      network_vif_ids = lb.load_balancer_targets.collect{|lt| lt.network_vif_id.split('-')[1]}
      if network_vif_ids
        M::NetworkVif.where(:uuid => network_vif_ids).all.each {|nv|
          tv = lb.target_network(nv.canonical_uuid)
          servers << {
            :ipv4 => nv.ip.first.ipv4,
            :backup => backup(tv.fallback_mode)
          }
        }
      end
    end

    if !params[:description].empty?
      lb.description = params[:description]
    end

    if !params[:display_name].empty?
      lb.display_name = params[:display_name]
    end

    lb.cookie_name = params[:cookie_name]

    lb.save_changes

    config_params = {
      :name=>"reload:haproxy",
      :instance_protocol => lb.instance_protocol,
      :instance_port => lb.instance_port,
      :port => lb.connect_port,
      :protocol => lb.protocol,
      :balance_algorithm => lb.balance_algorithm,
      :cookie_name => lb.cookie_name,
      :servers => servers
    }

    queue_params = {
      :topic_name => lb.topic_name,
      :queue_options => lb.queue_options,
      :queue_name => lb.queue_name,
    }

    on_after_commit do
      if lb.is_secure?
        Dcmgr::Messaging::LoadBalancer.update_ssl_proxy_config({
          :name => 'reload:stud',
          :accept_port => lb.accept_port,
          :connect_port => lb.connect_port,
          :protocol => lb.protocol,
          :private_key => lb.private_key,
          :public_key => lb.public_key
        }.merge(queue_params))
      end
      Dcmgr::Messaging::LoadBalancer.update_load_balancer_config(config_params.merge(queue_params))
    end

    respond_with(R::LoadBalancer.new(lb).generate)
  end

  put '/:id/poweron' do
    lb = find_by_uuid(:LoadBalancer, params[:id])
    raise E::UnknownInstance if lb.nil?
    i = lb.instance

    request_forward.put("/instances/#{i.canonical_uuid}/poweron")
    respond_with({:load_balancer_id=>lb.canonical_uuid})
  end

  put '/:id/poweroff' do
    lb = find_by_uuid(:LoadBalancer, params[:id])
    raise E::UnknownInstance if lb.nil?
    i = lb.instance

    request_forward.put("/instances/#{i.canonical_uuid}/poweroff")
    respond_with({:load_balancer_id=>lb.canonical_uuid})
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

  def backup(fallback_mode)
    fallback_mode == 'on' ? true : false
  end

  def create_security_group(rules)
   http_status, headers, body = internal_request("/api/12.03/security_groups.json",{
      'account_id' => @account.canonical_uuid,
      'rule' => rules.join("\n"),
      'service_type' => SERVICE_TYPE,
      'description' => '',
      'display_name' => ''
    }, {
      'PATH_INFO' => '/security_groups',
    })
    body['uuid']
  end

  def set_vif_sg(action,vif_id,sg_id)
    path = "/network_vifs/#{vif_id}/#{action}_security_group"
    uri = "/api/12.03/#{path}"
    http_status, headers, body = internal_request(uri,{
      'security_group_id' => sg_id
    }, {
      'PATH_INFO' => "#{path}",
      'REQUEST_METHOD' => 'PUT',
      'REQUEST_URI' => uri,
      'REQUEST_PATH' => uri
    })
    body
  end

end
