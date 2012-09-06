#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

module Dcmgr::SpecConvertor

  SPEC_FILE_ROOT_DIR = File.expand_path("../../../config/convert_specs", __FILE__)

  class SpecConvertor
    attr_reader :hypervisor, :cpu_cores, :memory_size, :quota_weight

    def convert(*args)
      raise NotImplementedError
    end

    private
    def load(file, key)
      path = File.join(SPEC_FILE_ROOT_DIR, file)
      begin
        config = YAML.load_file(path)
      rescue ::Exception => e
        raise "#{file} not found."
      end

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
      load('load_balancer.yml', max_connection)
    end
  end
end
