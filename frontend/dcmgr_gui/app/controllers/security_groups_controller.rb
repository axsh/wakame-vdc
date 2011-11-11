class SecurityGroupsController < ApplicationController
  respond_to :json
  
  def index
  end
  
  # security_groups/show/1.json
  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    @netfilter_group = DcmgrResource::NetfilterGroup.list(data)
    respond_with(@netfilter_group[0],:to => [:json])
  end
  
  # security_groups/detail/s-000001.json
  def show
    uuid = params[:id]
    @netfilter_group = DcmgrResource::NetfilterGroup.show(uuid)
    respond_with(@netfilter_group,:to => [:json])
  end

  def create
    data = {
      :description => params[:description],
      :rule => params[:rule]
    }
    @netfilter_group = DcmgrResource::NetfilterGroup.create(data)
    render :json => @netfilter_group
  end
  
  def destroy
    uuid = params[:id]
    @netfilter_group = DcmgrResource::NetfilterGroup.destroy(uuid)
    render :json => @netfilter_group    
  end
  
  def update
    uuid = params[:id]
    data = {
      :description => params[:description],
      :rule => params[:rule]
    }
    @netfilter_group = DcmgrResource::NetfilterGroup.update(uuid,data)
    render :json => @netfilter_group    
  end
  
  def show_groups
    @netfilter_group = DcmgrResource::NetfilterGroup.list
    respond_with(@netfilter_group[0],:to => [:json])
  end
  
  def total
   total_resource = DcmgrResource::NetfilterGroup.total_resource
   render :json => total_resource
  end
end