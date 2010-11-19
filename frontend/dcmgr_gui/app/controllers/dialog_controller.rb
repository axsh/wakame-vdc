class DialogController < ApplicationController
  layout false
  
  def create_volume
  end
  
  def create_volume_from_snapshot
    @snapshot_ids = params[:ids]
  end

  def attach_volume
    @volume_id = params[:ids][0]
  end
  
  def detach_volume
    @volume_ids = params[:ids]
  end
  
  def delete_volume
    @volume_ids = params[:ids]
  end
  
  def create_snapshot
    @volume_ids = params[:ids]
  end
  
  def delete_snapshot
    @snapshot_ids = params[:ids]
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
  
  def create_security_group
    @uuid = ''
    @description = ''
    @rule = ''
    render :create_and_edit_security_group
  end
  
  def delete_security_group
    @uuid = params[:ids][0]
    @netfilter_group = DcmgrResource::NetfilterGroup.show(@uuid)
    @name = @netfilter_group['name']
  end
  
  def edit_security_group
    @uuid = params[:ids][0]
    @netfilter_group = DcmgrResource::NetfilterGroup.show(@uuid)
    
    @name = @netfilter_group['name'] 
    @description =  @netfilter_group["description"]
    @rule = @netfilter_group["rule"]
    render :create_and_edit_security_group
  end
  
  def launch_instance
    @image_id = params[:ids][0]
  end
  
  def create_ssh_keypair
  end
  
  def delete_ssh_keypair
    @ssh_keypair_id = params[:ids][0]
  end
end
