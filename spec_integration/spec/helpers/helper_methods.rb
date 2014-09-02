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

def wait_instance(instance)
  loop do
    sleep(1)
    break if not Mussel::Instance.show(instance.id).vif.empty?
  end
  # TODO wait until network ready
  Mussel::Instance.show(instance.id)
end
