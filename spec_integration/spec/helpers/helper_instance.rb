# -*- coding: utf-8 -*-

def launch_instance
  instance_params[:vifs] = {
    'eth0' => {'index'=>'0', 'network'=>@network.id}
  }
  n = instance_params[:vifs].size
  instance_params[:vifs].merge!({
    "eth#{n}" => {"index" => n, "network" => config[:nw_management_uuid]}
  })

  setup_vif(instance_params)
  output_keyfile = create_ssh_key_pair(instance_params)

  @instance = wait_instance(Mussel::Instance.create(instance_params), config[:nw_management_uuid])

  @key_files ||= {}
  @key_files[@instance.id] = output_keyfile
end

def wait_instance(instance, network_uuid)
  instance = wait_until_vif_ready(instance.id)
  ip = extract_management_ip_address(instance.vif)
  ping_until_vif_ready(ip)
  instance
end

def wait_until_vif_ready(instance_uuid)
  loop do
    sleep(1)
    ret = Mussel::Instance.show(instance_uuid)
    break if not ret.vif.empty?
  end
  instance = Mussel::Instance.show(instance_uuid)
  p instance.inspect
  instance
end

def extract_management_ip_address(vifs)
  v = vifs.select { |vif|
    vif['network_id'] == config[:nw_management_uuid]
  }
  v.first['ipv4']['address']
end

def ping_until_vif_ready(ip)
  trial = 1
  loop do
    sleep(1)
    ping_success = system("ping -c 1 #{ip}")
    trial = trial + 1
    break if ping_success || (trial > config[:trial_limit])
  end
end

def terminate_instance
  ret = Mussel::Instance.destroy(@instance)
  expect(ret.first).to eq @instance.id
end

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
