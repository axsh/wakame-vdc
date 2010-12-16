namespace :api do
  desc 'Create proxy configuration file.'
  task :create_proxy_config => :environment do |t,args|
    base_dir = Dir.getwd
    filename = "./tmp/proxy.conf"

    config_file = ERB.new File.new("./app/api/proxy_nginx.conf", "r").read
    File.open(filename, "w+") { |f| f.write(config_file.result(binding)) }

    puts "Created new proxy configuration file: '#{filename}'."
  end

  desc 'Start proxy server'
  task :start_proxy => :environment do |t,args|
    exec "sudo -u #{DcmgrGui::Application.config.proxy_root_user} nginx -c #{Dir.getwd}/tmp/proxy.conf"

    puts "Nginx proxy server up and running."
  end

  desc 'Stop proxy server'
  task :stop_proxy => :environment do |t,args|
    exec "sudo -u #{DcmgrGui::Application.config.proxy_root_user} nginx -s stop -c #{Dir.getwd}/tmp/proxy.conf"

    puts "Nginx proxy server shut down."
  end
  
  task :start_auth => :environment do |t,args|
    exec "rackup -o localhost -p 8081 config-api.ru"
    
    puts "Auth server up and runing"
  end
end
