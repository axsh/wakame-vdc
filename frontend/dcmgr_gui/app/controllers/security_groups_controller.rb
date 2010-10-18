class SecurityGroupsController < ApplicationController
  respond_to :json
  
  def index
  end
  
  # security_groups/show/1.json
  def show
    json = Frontend::Models::DcmgrResource::Mock.load('security_groups/list')
    @instances = JSON.load(json)

    page = params[:id].to_i
    limit = 10
    from = ((page -1) * limit).to_i
    to = (from + limit -1).to_i
    respond_with(@instances[from..to],:to => [:json])
  end
  
  # security_groups/detail/s-000001.json
  def detail
    instance_id = params[:id]
    json = Frontend::Models::DcmgrResource::Mock.load('security_groups/details')
    @detail = JSON.load(json)
    respond_with(@detail[instance_id],:to => [:json])
  end
end