# -*- coding: utf-8 -*-

module Mussel
  class Instance < Base
    @mussel_instance_id = 0
    @ssh_key_pair_path = File.dirname(__FILE__)
    @vifs_path = File.dirname(__FILE__)

    def self.create(params)
      setup_vif(params)
      create_ssh_key_pair
      super(params)
      wait_instance
    end

    def self.create_ssh_key_pair
      @mussel_instance_id = @mussel_instance_id + 1
      output_keyfile="#{@ssh_key_pair_path}/key_pair.#{$$}_#{@mussel_instance_id}"
      system("ssh-keygen -N '' -f #{output_keyfile} -C #{output_keyfile}")
      ret = SshKeyPair.create({
        :description => output_keyfile,
        :public_key => "#{output_keyfile}.pub"
      })
    end

    def self.setup_vif(params)
      output_vifsfile="#{@vifs_path}/vifs.#{$$}_#{@mussel_instance_id}"
      File.write(output_vifsfile, params[:vifs].to_s.gsub("=>",":"))
      params.delete(:vifs)
      params[:vifs] = output_vifsfile
    end

    def self.wait_instance
    end
  end
end
