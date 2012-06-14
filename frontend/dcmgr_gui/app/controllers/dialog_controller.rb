require "yaml"

class DialogController < ApplicationController
  layout false
  
  def create_volume
  end
  
  def create_volume_from_backup
    @backup_object_ids = params[:ids]
  end

  def attach_volume
    @volume_ids = params[:ids]
  end
  
  def detach_volume
    @volume_ids = params[:ids]
  end
  
  def delete_volume
    @volume_ids = params[:ids]
  end
  
  def edit_volume
    @volume_id = params[:ids][0]
    @volume = Hijiki::DcmgrResource::Volume.show(@volume_id)
    @display_name = @volume["display_name"]
  end

  def create_backup
    @volume_ids = params[:ids]
  end
  
  def delete_backup
    @backup_object_ids = params[:ids]
  end
  
  def start_instances
    @instance_ids = params[:ids]
  end
  
  def stop_instances
    @instance_ids = params[:ids]
  end
  
  def reboot_instances
    @instance_ids = params[:ids]
  end
  
  def terminate_instances
    @instance_ids = params[:ids]
  end
  
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
    @uuid = params[:ids][0]
    @security_group = Hijiki::DcmgrResource::SecurityGroup.show(@uuid)
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
end
