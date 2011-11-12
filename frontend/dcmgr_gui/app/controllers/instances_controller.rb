class InstancesController < ApplicationController
  respond_to :json
  
  def index
  end
  
  def create
    data = {
      :image_id => params[:image_id],
      :instance_spec_id => params[:instance_spec_id],
      :host_pool_id => params[:host_pool_id],
      :host_name => params[:host_name],
      :user_data => params[:user_data],
      :security_groups => params[:security_groups],
      :ssh_key => params[:ssh_key]
    }
    instance = DcmgrResource::Instance.create(params)
    render :json => instance
  end
  
  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    instances = DcmgrResource::Instance.list(data)
    respond_with(instances[0],:to => [:json])
  end
  
  def show
    instance_id = params[:id]
    detail = DcmgrResource::Instance.show(instance_id)
    respond_with(detail,:to => [:json])
  end
  
  def terminate
    instance_ids = params[:ids]
    res = []
    instance_ids.each do |instance_id|
      res << DcmgrResource::Instance.destroy(instance_id)
    end
    render :json => res
  end
  
  def reboot
    instance_ids = params[:ids]
    res = []
    instance_ids.each do |instance_id|
      res << DcmgrResource::Instance.reboot(instance_id)
    end
    render :json => res
  end
  
  def total
   all_resource_count = DcmgrResource::Instance.total_resource
   all_resources = DcmgrResource::Instance.find(:all,:params => {:start => 0, :limit => all_resource_count})
   resources = all_resources[0].results
   terminated_resource_count = DcmgrResource::Instance.get_resource_state_count(resources, 'terminated')
   total = all_resource_count - terminated_resource_count
   render :json => total
  end
  
end
