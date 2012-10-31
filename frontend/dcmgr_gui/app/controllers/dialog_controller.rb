require "yaml"

class DialogController < ApplicationController
  layout false
  
  def create_volume
  end
  
  def create_volume_from_backup
    catch_error do
      @backup_object_ids = params[:ids]
      @backup_objects = []
      @backup_object_ids.each do |b|
        @backup_objects << Hijiki::DcmgrResource::BackupObject.show(b)
      end
    end
  end

  def attach_volume
    catch_error do
      @volume_ids = params[:ids]
      @volumes = []
      @volume_ids.each do |v|
        @volumes << Hijiki::DcmgrResource::Volume.show(v)
      end
    end
  end
  
  def detach_volume
    catch_error do
      @volume_ids = params[:ids]
      @volumes = []
      @volume_ids.each do |v|
        @volumes << Hijiki::DcmgrResource::Volume.show(v)
      end
    end
  end
  
  def delete_volume
    catch_error do
      @volume_ids = params[:ids]
      @volumes = []
      @volume_ids.each do |v|
        @volumes << Hijiki::DcmgrResource::Volume.show(v)
      end
    end
  end
  
  def edit_volume
    catch_error do
      @volume_id = params[:ids][0]
      @volume = Hijiki::DcmgrResource::Volume.show(@volume_id)
      @display_name = @volume["display_name"]
    end
  end

  def create_backup
    catch_error do
      @volume_ids = params[:ids]
      @volumes = []
      @volume_ids.each do |v|
        @volumes << Hijiki::DcmgrResource::Volume.show(v)
      end
    end
  end
  
  def delete_backup
    catch_error do
      @backup_object_ids = params[:ids]
      @backup_objects = []
      @backup_object_ids.each do |b|
        @backup_objects << Hijiki::DcmgrResource::BackupObject.show(b)
      end
    end
  end

  def edit_backup
    catch_error do
      @backup_object_id = params[:ids][0]
      @backup_object = Hijiki::DcmgrResource::BackupObject.show(@backup_object_id)
      @display_name = @backup_object["display_name"]
    end
  end
  
  def create_network
  end

  def edit_network
    catch_error do
      @network_id = params[:ids][0]
      @network = Hijiki::DcmgrResource::Network.show(@network_id)
      @display_name = @network["display_name"]
    end
  end

  def start_instances
    catch_error do
      @instance_ids = params[:ids]
      @instances = []
      @instance_ids.each do |i|
        @instances << Hijiki::DcmgrResource::Instance.show(i)
      end
    end
  end
  
  def stop_instances
    catch_error do
      @instance_ids = params[:ids]
      @instances = []
      @instance_ids.each do |i|
        @instances << Hijiki::DcmgrResource::Instance.show(i)
      end
    end
  end
  
  def reboot_instances
    catch_error do
      @instance_ids = params[:ids]
      @instances = []
      @instance_ids.each do |i|
        @instances << Hijiki::DcmgrResource::Instance.show(i)
      end
    end
  end
  
  def terminate_instances
    catch_error do
      @instance_ids = params[:ids]
      @instances = []
      @instance_ids.each do |i|
        @instances << Hijiki::DcmgrResource::Instance.show(i)
      end
    end
  end
  
  def backup_instances
    catch_error do
      @instance_id = params[:ids].first
      @instance = Hijiki::DcmgrResource::Instance.show(@instance_id)
    end
  end

  alias :poweroff_instances :reboot_instances
  alias :poweron_instances :reboot_instances

  
  def edit_instance
    catch_error do
      @instance_id = params[:ids][0]
      @instance = Hijiki::DcmgrResource::Instance.show(@instance_id)
      @display_name = @instance["display_name"]
      @monitoring = @instance["monitoring"]
      @vifs = []
      @instance['vif'].each { |vif|
        @vifs << vif
      }
    end
  end

  def create_security_group
    @description = ''
    @rule = ''
    render :create_and_edit_security_group
  end
  
  def delete_security_group
    catch_error do
      @security_group_id = params[:ids][0]
      @security_group = Hijiki::DcmgrResource::SecurityGroup.show(@security_group_id)
      @display_name = @security_group["display_name"]
    end
  end
  
  def edit_security_group
    catch_error do
      @uuid = params[:ids][0]
      @security_group = Hijiki::DcmgrResource::SecurityGroup.show(@uuid)

      @description =  @security_group["description"]
      @display_name =  @security_group["display_name"]
      @rule = @security_group["rule"]
      render :create_and_edit_security_group
    end
  end
  
  def launch_instance
    @image_id = params[:ids][0]
  end

  def edit_machine_image
    catch_error do
      @uuid = params[:ids][0]
      @machine_image = Hijiki::DcmgrResource::Image.show(@uuid)
      @display_name = @machine_image["display_name"]
      @description = @machine_image["description"]
    end
  end
  
  def delete_backup_image
    catch_error do
      uuid = params[:ids][0]
      backup_image = Hijiki::DcmgrResource::Image.show(uuid)
      @image_id = backup_image["uuid"]
      @display_name = backup_image["display_name"]
    end
  end

  def create_ssh_keypair
    render :create_and_edit_ssh_keypair
  end
  
  def delete_ssh_keypair
    catch_error do
      @ssh_keypair_id = params[:ids][0]
      @ssh_keypair = Hijiki::DcmgrResource::SshKeyPair.show(@ssh_keypair_id)
      @display_name = @ssh_keypair["display_name"]
    end
  end

  def edit_ssh_keypair
    catch_error do
      @uuid = params[:ids][0]
      @ssh_keypair = Hijiki::DcmgrResource::SshKeyPair.show(@uuid)
      @display_name = @ssh_keypair["display_name"]
      @description = @ssh_keypair["description"]
      render :create_and_edit_ssh_keypair
    end
  end

  def create_load_balancer
    @load_balancer_ids = params[:ids]
    @display_name = ''
    @description = ''
    @protocol = ''
    @port = ''
    @instance_protocol = ''
    @instance_port = ''
    @balance_algorithm = ''
    @private_key = ''
    @public_key = ''
    @cookie_name = ''
    render :create_and_edit_load_balancer
  end

  def delete_load_balancer
    catch_error do
      @load_balancer_id = params[:ids][0]
      @load_balancer = Hijiki::DcmgrResource::LoadBalancer.show(@load_balancer_id)
      @display_name = @load_balancer["display_name"]
    end
  end

  def register_load_balancer
    catch_error do
      @load_balancer_id = params[:ids][0]
      @load_balancer = Hijiki::DcmgrResource::LoadBalancer.show(@load_balancer_id)
      @display_name = @load_balancer["display_name"]
    end
  end

  def unregister_load_balancer
    catch_error do
      @load_balancer_id = params[:ids][0]
      @load_balancer = Hijiki::DcmgrResource::LoadBalancer.show(@load_balancer_id)
      @display_name = @load_balancer["display_name"]
    end
  end

  def poweron_load_balancer
    catch_error do
      @load_balancer_id = params[:ids][0]
      @load_balancer = Hijiki::DcmgrResource::LoadBalancer.show(@load_balancer_id)
      @display_name = @load_balancer["display_name"]
    end
  end

  def poweroff_load_balancer
    catch_error do
      @load_balancer_id = params[:ids][0]
      @load_balancer = Hijiki::DcmgrResource::LoadBalancer.show(@load_balancer_id)
      @display_name = @load_balancer["display_name"]
    end
  end

  def edit_load_balancer
    catch_error do
      @uuid = params[:ids][0]
      @load_balancer = Hijiki::DcmgrResource::LoadBalancer.show(@uuid)
      @display_name = @load_balancer["display_name"]
      @description = @load_balancer["description"]
      @protocol = @load_balancer["protocol"]
      @port = @load_balancer["port"]
      @instance_protocol = @load_balancer["instance_protocol"]
      @instance_port = @load_balancer["instance_port"]
      @balance_algorithm = @load_balancer["balance_algorithm"]
      @private_key = @load_balancer["private_key"]
      @public_key = @load_balancer["public_key"]
      @cookie_name = @load_balancer["cookie_name"]
      render :create_and_edit_load_balancer
    end
  end

  def active_standby_load_balancer
    catch_error do
      @load_balancer_id = params[:ids][0]
      @load_balancer = Hijiki::DcmgrResource::LoadBalancer.show(@load_balancer_id)
      @display_name = @load_balancer["display_name"]
    end
  end

end
