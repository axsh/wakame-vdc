class LoadBalancersController < ApplicationController
  respond_to :json
  include Util

  def index
  end

  def show
    volume_id = params[:id]
    detail = Hijiki::DcmgrResource::LoadBalancer.show(volume_id)
    respond_with(detail,:to => [:json])
  end

  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    volumes = Hijiki::DcmgrResource::LoadBalancer.list(data)
    respond_with(volumes[0],:to => [:json])
  end

  def total
     all_resource_count = Hijiki::DcmgrResource::LoadBalancer.total_resource
     all_resources = Hijiki::DcmgrResource::LoadBalancer.find(:all,:params => {:start => 0, :limit => all_resource_count})
     resources = all_resources[0].results
     deleted_resource_count = Hijiki::DcmgrResource::LoadBalancer.get_resource_state_count(resources, 'deleted')
     total = all_resource_count - deleted_resource_count
     render :json => total
   end
end
