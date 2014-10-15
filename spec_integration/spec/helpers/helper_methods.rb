# -*- coding: utf-8 -*-

SSH_OPTS = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

def recursive_symbolize_keys(hash)
  hash.each_with_object({}){|(k,v), m|
    m[k.to_s.to_sym] = (v.is_a?(Hash) ? recursive_symbolize_keys(v) : v)
  }
end

def config
  @config ||= recursive_symbolize_keys(YAML.load_file(File.expand_path("../../../config/config.yml", __FILE__)))
end

def create_virtual_network_nw_demo1
  @network = Mussel::Network.create(nw_demo1_params)
end
