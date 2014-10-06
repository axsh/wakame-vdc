# -*- coding: utf-8 -*-

SSH_OPTS = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

def setup_vif(params)
  output_vifsfile="#{File.dirname(__FILE__)}/vifs.#{$$}.#{Time.now.strftime("%Y%m%d%H%M%S")}"
  File.write(output_vifsfile, params[:vifs].to_s.gsub("=>",":"))
  params.delete(:vifs)
  params[:vifs] = output_vifsfile
end

def create_ssh_key_pair(params)
  output_keyfile="#{File.dirname(__FILE__)}/key_pair.#{$$}.#{Time.now.strftime("%Y%m%d%H%M%S")}"
  system("ssh-keygen -N '' -f #{output_keyfile} -C #{output_keyfile}")
  ssh_key_pair = Mussel::SshKeyPair.create({
    :description => output_keyfile,
    :public_key => "#{output_keyfile}.pub"
  })
  params[:ssh_key_id] = ssh_key_pair.id
  output_keyfile
end

def wait_instance(instance, network_uuid)
  trial_limit = 40
  trial = 0

  loop do
    sleep(1)
    ret = Mussel::Instance.show(instance.id)
    break if not ret.vif.empty?
  end

  instance = Mussel::Instance.show(instance.id)
  p instance.inspect
  ip = extract_ip_address(instance, network_uuid)

  loop do
    sleep(1)
    ping_success = system("ping -c 1 #{ip}")
    trial = trial + 1
    break if ping_success || (trial >= trial_limit)
  end

  instance
end

def extract_ip_address(instance, network_uuid)
  instance.vif.select do |v|
    v['network_id'] == network_uuid
  end.first['ipv4']['address']
end

def recursive_symbolize_keys(hash)
  hash.each_with_object({}){|(k,v), m|
    m[k.to_s.to_sym] = (v.is_a?(Hash) ? recursive_symbolize_keys(v) : v)
  }
end

def config
  @config ||= recursive_symbolize_keys(YAML.load_file(File.expand_path("../../../config/config.yml", __FILE__)))
end
