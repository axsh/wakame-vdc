class InstancesController < ApplicationController
  respond_to :json
  
  def index
  end
  
  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    instances = Frontend::Models::DcmgrResource::Instance.list(data)
    respond_with(instances[0],:to => [:json])
  end
  
  # instance/show/1.json
  def show
    json = Frontend::Models::DcmgrResource::Mock.load('instances/list')
    @instances = JSON.load(json)

    page = params[:id].to_i
    limit = 10
    from = ((page -1) * limit).to_i
    to = (from + limit -1).to_i
    respond_with(@instances[from..to],:to => [:json])
  end
  
  # instance/detail/i-5c5fe70a.json
  def detail
    instance_id = params[:id]
    json = Frontend::Models::DcmgrResource::Mock.load('instances/details')
    @detail = JSON.load(json)
    respond_with(@detail[instance_id],:to => [:json])
  end
end