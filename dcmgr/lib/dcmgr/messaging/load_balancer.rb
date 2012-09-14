#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

module Dcmgr::Messaging
  module LoadBalancer
    def self.update_ssl_proxy_config(values)
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
      Dcmgr::Messaging.publish(values[:private_key], queue_params.merge({:name => 'write:private_key'}))
      Dcmgr::Messaging.publish(values[:public_key], queue_params.merge({:name => 'write:public_key'}))
      Dcmgr::Messaging.publish(stunnel_config, queue_params.merge({:name => values[:name]}))
    end

    def self.update_load_balancer_config(values)
      proxy = Dcmgr::Drivers::Haproxy.new(Dcmgr::Drivers::Haproxy.mode(values[:protocol]))
      proxy.set_balance_algorithm(values[:balance_algorithm])
      proxy.set_cookie_name(values[:cookie_name]) if !values[:cookie_name].empty?
      proxy.set_bind('*', values[:port])

      if !values[:servers].empty?
        values[:servers].each do |t|
          options = {}
          options = {:backup => t[:backup]} if t.include? :backup
          proxy.add_server(t[:ipv4], values[:instance_port], options)
        end
      end

      haproxy_config = proxy.bind_template(proxy.template_file_path)
      queue_params = {
        :name => values[:name],
        :topic_name => values[:topic_name],
        :queue_options => values[:queue_options],
        :queue_name => values[:queue_name]
      }

      if ['http', 'tcp'].include? values[:protocol]
        Dcmgr::Messaging.publish('', queue_params.merge({:name => 'stop:stunnel'}))
      end
      Dcmgr::Messaging.publish(haproxy_config, queue_params)
    end

  end
end
