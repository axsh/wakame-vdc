#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

module Dcmgr::SpecConvertor

  SPEC_FILE_DIRS = ["/etc/wakame-vdc/convert_specs", File.expand_path("../../../config/convert_specs", __FILE__)]

  class SpecConvertor
    attr_reader :hypervisor, :cpu_cores, :memory_size, :quota_weight

    def convert(*args)
      raise NotImplementedError
    end

    private
    def load(file, key)
      dir = SPEC_FILE_DIRS.find {|d| File.exists?(File.join(d,file)) }
      raise "#{file} not found." if dir.nil?
      path = File.join(dir, file)
      config = YAML.load_file(path)

      raise "#{key} key does not exist" if config[key].nil?

      c = config[key]
      @hypervisor = c['hypervisor']
      @cpu_cores = c['cpu_cores']
      @memory_size = c['memory_size']
      @quota_weight = c['quota_weight']
      true
    end
  end

  class LoadBalancer < SpecConvertor
    def convert(engine, max_connection)
      if engine != 'haproxy'
        raise ArgumentError, "#{engine} isn't implmented"
      end
      load('load_balancer.yml', max_connection.to_i)
    end
  end
end
