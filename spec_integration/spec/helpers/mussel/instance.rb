# -*- coding: utf-8 -*-

module Mussel
  class Instance < Base
    @mussel_instance_id = 0
    @ssh_key_pair_path = File.dirname(__FILE__)
    @vifs_path = File.dirname(__FILE__)

    class << self
      def create(params)
        setup_vif(params)
        create_ssh_key_pair(params)
        wait_instance(super(params))
      end

      def destroy(instance)
        super(instance.id)
        SshKeyPair.destroy(instance.ssh_key_pair['uuid'])
      end

      def create_ssh_key_pair(params)
        @mussel_instance_id = @mussel_instance_id + 1
        output_keyfile="#{@ssh_key_pair_path}/key_pair.#{$$}_#{@mussel_instance_id}"
        system("ssh-keygen -N '' -f #{output_keyfile} -C #{output_keyfile}")
        ssh_key_pair = SshKeyPair.create({
          :description => output_keyfile,
          :public_key => "#{output_keyfile}.pub"
        })
        params[:ssh_key_id] = ssh_key_pair.id
      end

      def setup_vif(params)
        output_vifsfile="#{@vifs_path}/vifs.#{$$}_#{@mussel_instance_id}"
        File.write(output_vifsfile, params[:vifs].to_s.gsub("=>",":"))
        params.delete(:vifs)
        params[:vifs] = output_vifsfile
      end

      def wait_instance(instance)
        loop do
          sleep(1)
          break if not show(instance.id).vif.empty?
        end
        # TODO wait until network ready
        show(instance.id)
      end
    end
  end

  module Responses
    class Instance < Base
    end
  end
end
