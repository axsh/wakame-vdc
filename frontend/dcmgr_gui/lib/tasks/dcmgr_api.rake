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

  desc 'Start auth server'
  task :start_auth_server => :environment do |t,args|
    rackup_file = "#{Dir.getwd}/app/api/config.ru"
    pid_file = "/var/run/wakame-auth.pid"
    host = DcmgrGui::Application.config.auth_host
    port = DcmgrGui::Application.config.auth_port
    command = "sudo rackup #{rackup_file} -D -o #{host} -p #{port} -P #{pid_file}"
    exec "#{command} > /dev/null || exit 0"
    puts "Auth server up and running."
  end
  
  desc 'Stop auth server'
  task :stop_auth_server => :environment do |t,args|
    pid_file = "/var/run/wakame-auth.pid"
    if File.exists? pid_file
      command = "sudo kill -SIGINT `cat #{pid_file}`"
      exec command
      puts "Auth server shut down."
    end
  end

end
