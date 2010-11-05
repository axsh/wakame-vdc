class DialogController < ApplicationController
  layout false
  
  def instance
    @image_id = params[:id]
  end
  
  def create_volume
  end
  
  def create_volume_from_snapshot
    @snapshot_ids = params[:ids]
  end

  def attach_volume
  end
  
  def detach_volume
    
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
  
  def createkey
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
    @netfilter_group = Frontend::Models::DcmgrResource::NetfilterGroup.show(@uuid)
    @name = @netfilter_group['name']
  end
  
  def edit_security_group
    @uuid = params[:ids][0]
    @netfilter_group = Frontend::Models::DcmgrResource::NetfilterGroup.show(@uuid)
    
    @name = @netfilter_group['name'] 
    @description =  @netfilter_group["description"]
    @rule = @netfilter_group["rule"]
    render :create_and_edit_security_group
  end
  
  def launch_instance
    @image_id = params[:ids][0]
  end
end
