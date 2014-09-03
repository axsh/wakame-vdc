# -*- coding: utf-8 -*-

def setup_vif(params)
  output_vifsfile="#{File.dirname(__FILE__)}/vifs.#{$$}"
  File.write(output_vifsfile, params[:vifs].to_s.gsub("=>",":"))
  params.delete(:vifs)
  params[:vifs] = output_vifsfile
end

def create_ssh_key_pair(params)
  output_keyfile="#{File.dirname(__FILE__)}/key_pair.#{$$}"
  system("ssh-keygen -N '' -f #{output_keyfile} -C #{output_keyfile}")
  ssh_key_pair = Mussel::SshKeyPair.create({
    :description => output_keyfile,
    :public_key => "#{output_keyfile}.pub"
  })
  params[:ssh_key_id] = ssh_key_pair.id
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
  target_vif = instance.vif.select do |v|
    v['network_id'] == network_uuid
  end.first
  ip = target_vif['ipv4']['address']

  loop do
    sleep(1)
    ping_success = system("ping -c 1 #{ip}")
    trial = trial + 1
    break if ping_success || (trial >= trial_limit)
  end

  instance
end
