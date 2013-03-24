#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

module Dcmgr::Messaging
  module LoadBalancer
    def self.update_ssl_proxy_config(values)
      s = Dcmgr::Drivers::Stud.new
      s.accept_port = values[:accept_port]
      s.connect_port = values[:connect_port]
      s.protocol = values[:protocol]
      stud_config = s.bind_template('stud.cfg')
      queue_params = {
        :topic_name => values[:topic_name],
        :queue_options => values[:queue_options],
        :queue_name => values[:queue_name]
      }

      Dcmgr::Messaging.publish("#{values[:private_key]}\n#{values[:public_key]}", queue_params.merge({:name => 'write:keys'}))
      Dcmgr::Messaging.publish(stud_config, queue_params.merge({:name => values[:name]}))
    end

    def self.update_load_balancer_config(values)
      proxy = Dcmgr::Drivers::Haproxy.new(Dcmgr::Drivers::Haproxy.mode(values[:instance_protocol]))
      proxy.set_balance_algorithm(values[:balance_algorithm])
      proxy.set_cookie_name(values[:cookie_name]) if !values[:cookie_name].blank?
      ports = values[:ports] + [values[:secure_port]]
      ports.each do |port|
        proxy.set_bind('*', port) unless port.nil?
      end

      if proxy.is_http?
        if !values[:secure_port].nil?
          proxy.set_x_forwarded_proto('https', values[:secure_port])
        end
        if !values[:ports].empty?
          ports = values[:ports] - [values[:secure_port]]
          proxy.set_x_forwarded_proto('http', ports)
        end

        if !values[:httpchk_path].blank?
          proxy.set_httpchk_path(values[:httpchk_path])
        end
      end

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
        Dcmgr::Messaging.publish('', queue_params.merge({:name => 'stop:stud'}))
      end
      Dcmgr::Messaging.publish(haproxy_config, queue_params)
    end
  end
end
