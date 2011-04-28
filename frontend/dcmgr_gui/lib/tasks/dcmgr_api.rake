def get_rackup_command(mode)
  default_mode = 'rackup'
  unless ['rackup', 'unicorn'].include? mode
    mode = default_mode 
  end
  mode
end

namespace :api do
  desc 'Create proxy configuration file.'
  task :create_proxy_config => :environment do |t,args|
    base_dir = Dir.getwd
    file = File.join(base_dir, 'config', 'proxy.conf')
    config_file = ERB.new File.new("./app/api/proxy_nginx.conf", "r").read
    File.open(file, "w+") { |f| f.write(config_file.result(binding)) }

    puts "Created new proxy configuration file: '#{file}'."
  end

  desc 'Start proxy server'
  task :start_proxy => :environment do |t,args|
    
    user = DcmgrGui::Application.config.proxy_root_user
    nginx = DcmgrGui::Application.config.proxy_nginx
    exec "sudo -u #{user} #{nginx} -c #{Dir.getwd}/config/proxy.conf"
    puts "Nginx proxy server up and running."
  end

  desc 'Stop proxy server'
  task :stop_proxy => :environment do |t,args|
    user = DcmgrGui::Application.config.proxy_root_user
    nginx = DcmgrGui::Application.config.proxy_nginx
    exec "sudo -u #{user} #{nginx} -s stop -c #{Dir.getwd}/config/proxy.conf"
    puts "Nginx proxy server shut down."
  end

  desc 'Create configuration file for auth server.'
  task :create_auth_server_config => :environment do |t,args|
    base_dir = Dir.getwd
    file = File.join(base_dir, 'config', 'auth_server.conf')
    config_file = ERB.new File.new("./app/api/auth_server.conf", "r").read
    File.open(file, "w+") { |f| f.write(config_file.result(binding)) }

    puts "Created auth server configuration file: '#{file}'."
  end

  desc 'Start auth server'
  task :start_auth_server,[:mode] => :environment do |t,args|
    mode = get_rackup_command(args['mode'])
    rackup_file = "#{Dir.getwd}/app/api/config.ru"
    pid_file = "/var/run/wakame-auth.pid"
    host = DcmgrGui::Application.config.auth_host
    port = DcmgrGui::Application.config.auth_port
    
    command = "sudo #{mode} #{rackup_file} -D -o #{host} -p #{port}"
    if mode == 'rackup'
      command = "#{command} -P #{pid_file}"
    elsif mode == 'unicorn'
      begin
        require 'unicorn'
      rescue ::LoadError => e
        abort(e.message)
      end
      command = "#{command} -c #{Dir.getwd}/config/auth_server.conf"
    end
    exec "#{command}"
    puts "Auth server up and running."
  end
  
  desc 'Stop auth server'
  task :stop_auth_server,[:mode] => :environment do |t,args|
    pid_file = "/var/run/wakame-auth.pid"
    if File.exists? pid_file
      mode = get_rackup_command(args['mode'])
      if mode == 'rackup'
        command = "sudo kill -SIGINT `cat #{pid_file}`"
      elsif mode == 'unicorn'
        command = "sudo kill -QUIT `cat #{pid_file}`"
      end
      exec command
      puts "Auth server shut down."
    end
  end

end
