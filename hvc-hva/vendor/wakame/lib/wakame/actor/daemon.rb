
require 'shellwords'
require 'ext/shellwords' unless Shellwords.respond_to? :shellescape

class Wakame::Actor::Daemon
  include Wakame::Actor

 
  def start(resource_dir, cmd)
    Wakame::Util.exec("/usr/bin/env #{env_opts} '#{cmd_abs_path(resource_dir, cmd.dup)}' start")
  end

  def stop(resource_dir, cmd)
    Wakame::Util.exec("/usr/bin/env #{env_opts} '#{cmd_abs_path(resource_dir, cmd.dup)}' stop")
  end

  def reload(resource_dir, cmd)
    Wakame::Util.exec("/usr/bin/env #{env_opts} '#{cmd_abs_path(resource_dir, cmd.dup)}' reload")
  end

  private
  def env_opts
    {'WAKAME_ROOT'=>Wakame.config.root_path}.map {|k,v|
      "#{k}='#{v}'"
    }.join(' ')
  end

  def resource_path(resource_dir)
    sprintf("%s/%s", Wakame.config.config_root, resource_dir)
  end

  def cmd_abs_path(resource_dir, cmd)
    Shellwords.shellescape(File.expand_path(cmd.sub(%r{^/}, ''), resource_path(resource_dir)))
  end

end

