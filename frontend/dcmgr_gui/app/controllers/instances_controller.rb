class InstancesController < ApplicationController
  respond_to :json
  
  def index
  end
  
  def create
    data = {
      :image_id => params[:image_id],
      :host_pool_id => params[:host_pool_id],
      :instance_spec => params[:instance_spec]
    }
    
    instance = Frontend::Models::DcmgrResource::Instance.create(data)
    render :json => instance
  end
  
  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    instances = Frontend::Models::DcmgrResource::Instance.list(data)
    respond_with(instances[0],:to => [:json])
  end
  
  def show
    instance_id = params[:id]
    detail = Frontend::Models::DcmgrResource::Instance.show(instance_id)
    respond_with(detail,:to => [:json])
  end
  
end