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
      :nf_group => params[:nf_group],
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
    response = []
    instance_ids.each do |instance_id|
      response << DcmgrResource::Instance.destroy(instance_id)
    end
    render :json => response
  end
  
  def reboot
    instance_ids = params[:ids]
    response = []
    instance_ids.each do |instance_id|
      response << DcmgrResource::Instance.reboot(instance_id)
    end
    render :json => response
  end
  
  def total
   total_resource = DcmgrResource::Instance.total_resource
   render :json => total_resource
  end
  
end