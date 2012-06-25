class LoadBalancersController < ApplicationController
  respond_to :json
  include Util

  def index
  end

  def create
     data = {
      :display_name => params[:display_name],
      :load_balancer_protocol => params[:load_balancer_protocol],
      :load_balancer_port => params[:load_balancer_port],
      :instance_protocol => params[:instance_protocol],
      :instance_port => params[:instance_port],
      :certificate_name => params[:certificate_name],
      :private_key => params[:private_key],
      :public_key => params[:public_key],
      :certificate_chain => params[:certificate_chain],
      :cookie_name => params[:cookie_name]
    }

    # TODO: specify instance spec id
    data[:instance_spec_id] = 'is-demospec'

    lb = Hijiki::DcmgrResource::LoadBalancer.create(data)
    render :json => lb
  end

  def show
    load_balancer_id = params[:id]
    detail = Hijiki::DcmgrResource::LoadBalancer.show(load_balancer_id)
    respond_with(detail,:to => [:json])
  end

  def destroy
    load_balancer_id = params[:id]
    detail = Hijiki::DcmgrResource::LoadBalancer.destroy(load_balancer_id)
    respond_with(detail,:to => [:json])
  end

  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    results = Hijiki::DcmgrResource::LoadBalancer.list(data)
    respond_with(results[0],:to => [:json])
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

  def destroy
    load_balancer_id = params[:id]
    detail = Hijiki::DcmgrResource::LoadBalancer.destroy(load_balancer_id)
