require "yaml"

class DialogController < ApplicationController
  layout false
  
  def create_volume
  end
  
  def create_volume_from_backup
    @backup_object_ids = params[:ids]
    @backup_objects = []
    @backup_object_ids.each do |b|
      @backup_objects << Hijiki::DcmgrResource::BackupObject.show(b)
    end
  end

  def attach_volume
    @volume_ids = params[:ids]
    @volumes = []
    @volume_ids.each do |v|
      @volumes << Hijiki::DcmgrResource::Volume.show(v)
    end
  end
  
  def detach_volume
    @volume_ids = params[:ids]
    @volumes = []
    @volume_ids.each do |v|
      @volumes << Hijiki::DcmgrResource::Volume.show(v)
    end
  end
  
  def delete_volume
    @volume_ids = params[:ids]
    @volumes = []
    @volume_ids.each do |v|
      @volumes << Hijiki::DcmgrResource::Volume.show(v)
    end
  end
  
  def edit_volume
    @volume_id = params[:ids][0]
    @volume = Hijiki::DcmgrResource::Volume.show(@volume_id)
    @display_name = @volume["display_name"]
  end

  def create_backup
    @volume_ids = params[:ids]
    @volumes = []
    @volume_ids.each do |v|
      @volumes << Hijiki::DcmgrResource::Volume.show(v)
    end
  end
  
  def delete_backup
    @backup_object_ids = params[:ids]
    @backup_objects = []
    @backup_object_ids.each do |b|
      @backup_objects << Hijiki::DcmgrResource::BackupObject.show(b)
    end
  end

  def edit_backup
    @backup_object_id = params[:ids][0]
    @backup_object = Hijiki::DcmgrResource::BackupObject.show(@backup_object_id)
    @display_name = @backup_object["display_name"]
  end
  
  def detach_vif
    @vif_id = params[:vif_id]
    @network_id = params[:network_id]
    @result = Hijiki::DcmgrResource::NetworkVif.find_vif(@network_id, @vif_id).detach
  end

  def start_instances
    @instance_ids = params[:ids]
    @instances = []
    @instance_ids.each do |i|
      @instances << Hijiki::DcmgrResource::Instance.show(i)
    end
  end
  
  def stop_instances
    @instance_ids = params[:ids]
    @instances = []
    @instance_ids.each do |i|
      @instances << Hijiki::DcmgrResource::Instance.show(i)
    end
  end
  
  def reboot_instances
    @instance_ids = params[:ids]
    @instances = []
    @instance_ids.each do |i|
      @instances << Hijiki::DcmgrResource::Instance.show(i)
    end
  end
  
  def terminate_instances
    @instance_ids = params[:ids]
    @instances = []
    @instance_ids.each do |i|
      @instances << Hijiki::DcmgrResource::Instance.show(i)
    end
  end
  
  def backup_instances
    @instance_ids = params[:ids]
    @instances = []
    @instance_ids.each do |i|
      @instances << Hijiki::DcmgrResource::Instance.show(i)
    end
  end

  alias :poweroff_instances :backup_instances
  alias :poweron_instances :backup_instances

  
  def edit_instance
    @instance_id = params[:ids][0]
    @instance = Hijiki::DcmgrResource::Instance.show(@instance_id)
    @display_name = @instance["display_name"]
  end

  def create_security_group
    @description = ''
    @rule = ''
    render :create_and_edit_security_group
  end
  
  def delete_security_group
    @security_group_id = params[:ids][0]
    @security_group = Hijiki::DcmgrResource::SecurityGroup.show(@security_group_id)
    @display_name = @security_group["display_name"]
  end
  
  def edit_security_group
    @uuid = params[:ids][0]
    @security_group = Hijiki::DcmgrResource::SecurityGroup.show(@uuid)

    @description =  @security_group["description"]
    @display_name =  @security_group["display_name"]
    @rule = @security_group["rule"]
    render :create_and_edit_security_group
  end
  
  def launch_instance
    @image_id = params[:ids][0]
  end

  def edit_machine_image
    @uuid = params[:ids][0]
    @machine_image = Hijiki::DcmgrResource::Image.show(@uuid)
    @display_name = @machine_image["display_name"]
    @description = @machine_image["description"]
  end
  
  def create_ssh_keypair
    render :create_and_edit_ssh_keypair
  end
  
  def delete_ssh_keypair
    @ssh_keypair_id = params[:ids][0]
    @ssh_keypair = Hijiki::DcmgrResource::SshKeyPair.show(@ssh_keypair_id)
    @display_name = @ssh_keypair["display_name"]
  end

  def edit_ssh_keypair
    @uuid = params[:ids][0]
    @ssh_keypair = Hijiki::DcmgrResource::SshKeyPair.show(@uuid)
    @display_name = @ssh_keypair["display_name"]
    @description = @ssh_keypair["description"]
    render :create_and_edit_ssh_keypair
  end

  def create_load_balancer
    @load_balancer_ids = params[:ids]
  end

  def delete_load_balancer
    @load_balancer_id = params[:ids][0]
    @load_balancer = Hijiki::DcmgrResource::LoadBalancer.show(@load_balancer_id)
    @display_name = @load_balancer["display_name"]
  end

end
