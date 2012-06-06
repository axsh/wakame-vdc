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
    @security_group = Hijiki::DcmgrResource::SecurityGroup.list(data)
    respond_with(@security_group[0],:to => [:json])
  end
  
  # security_groups/detail/s-000001.json
  def show
    uuid = params[:id]
    @security_group = Hijiki::DcmgrResource::SecurityGroup.show(uuid)
    respond_with(@security_group,:to => [:json])
  end

  def create
    data = {
      :display_name => params[:display_name],
      :description => params[:description],
      :rule => params[:rule]
    }
    @security_group = Hijiki::DcmgrResource::SecurityGroup.create(data)
    render :json => @security_group
  end
  
  def destroy
    uuid = params[:id]
    @security_group = Hijiki::DcmgrResource::SecurityGroup.destroy(uuid)
    render :json => @security_group    
  end
  
  def update
    uuid = params[:id]
    data = {
      :description => params[:description],
      :rule => params[:rule]
    }
    @security_group = Hijiki::DcmgrResource::SecurityGroup.update(uuid,data)
    render :json => @security_group    
  end
  
  def show_groups
    @security_group = Hijiki::DcmgrResource::SecurityGroup.list
    respond_with(@security_group[0],:to => [:json])
  end
  
  def total
   total_resource = Hijiki::DcmgrResource::SecurityGroup.total_resource
   render :json => total_resource
  end
end
