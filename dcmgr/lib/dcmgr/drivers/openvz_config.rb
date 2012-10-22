# -*- coding: utf-8 -*-

class OpenvzConfig

  def initialize
    # load vz.conf
    config_file = "/etc/vz/vz.conf"
    raise "vz.conf does not exist" unless File.exists?(config_file)
    @config = Hash.new
    File.new(config_file).read.chomp.split("\n").each do |f|
      k, v = f.split(/=/)
      @config[k] = v
    end
    @config["VE_CONFIG_DIR"] = File.dirname(config_file) + "/conf"
  end

  def ve_config_dir
    @config["VE_CONFIG_DIR"]
  end

  def ve_root
    File.dirname(@config["VE_ROOT"])
  end

  def ve_private
    File.dirname(@config["VE_PRIVATE"])
  end

  def template
    @config["TEMPLATE"]
  end

  def template_cache
    File.join(@config["TEMPLATE"], 'cache')
  end
end
