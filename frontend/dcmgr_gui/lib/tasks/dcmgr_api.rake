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
    exec "sudo -u #{user} nginx -c #{Dir.getwd}/config/proxy.conf"
    puts "Nginx proxy server up and running."
  end

  desc 'Stop proxy server'
  task :stop_proxy => :environment do |t,args|
    user = DcmgrGui::Application.config.proxy_root_user
    exec "sudo -u #{user} nginx -s stop -c #{Dir.getwd}/config/proxy.conf"
    puts "Nginx proxy server shut down."
  end
end
