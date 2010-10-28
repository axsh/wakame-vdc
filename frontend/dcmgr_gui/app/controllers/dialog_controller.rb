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
  end
  
  def delete_security_group
    @name = params[:ids][0]
  end
  
  def edit_security_group
  end
  
  def launch_instance
    @image_id = params[:ids][0]
  end
end
