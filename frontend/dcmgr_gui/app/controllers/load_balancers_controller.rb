class LoadBalancersController < ApplicationController
  respond_to :json
  include Util

  def index
  end

  def create
    catch_error do
      data = {
        :display_name => params[:display_name],
        :description => params[:description],
        :protocol => params[:load_balancer_protocol],
        :port => params[:load_balancer_port],
        :instance_protocol => params[:instance_protocol],
        :instance_port => params[:instance_port],
        :balance_algorithm => params[:balance_algorithm],
        :certificate_name => params[:certificate_name],
        :private_key => params[:private_key],
        :public_key => params[:public_key],
        :cookie_name => params[:cookie_name],
        :load_balancer_spec_id => Rails::configuration.load_balancer_spec_id
      }
      lb = Hijiki::DcmgrResource::LoadBalancer.create(data)
      render :json => lb
    end
  end

  def show
    catch_error do
      load_balancer_id = params[:id]
      detail = Hijiki::DcmgrResource::LoadBalancer.show(load_balancer_id)
      respond_with(detail,:to => [:json])
    end
  end

  def destroy
    catch_error do
      load_balancer_id = params[:id]
      detail = Hijiki::DcmgrResource::LoadBalancer.destroy(load_balancer_id)
      render :json => detail
    end
  end

  def list
    catch_error do
      data = {
        :start => params[:start].to_i - 1,
        :limit => params[:limit]
      }
      results = Hijiki::DcmgrResource::LoadBalancer.list(data)
      respond_with(results[0],:to => [:json])
    end
  end

  def total
    catch_error do
      all_resource_count = Hijiki::DcmgrResource::LoadBalancer.total_resource
      all_resources = Hijiki::DcmgrResource::LoadBalancer.find(:all,:params => {:start => 0, :limit => all_resource_count})
      resources = all_resources[0].results
      deleted_resource_count = Hijiki::DcmgrResource::LoadBalancer.get_resource_state_count(resources, 'deleted')
      total = all_resource_count - deleted_resource_count
      render :json => total
    end
   end

   def register_instances
     catch_error do
       load_balancer_id = params[:load_balancer_id]
       vifs = params[:vifs]
       res = Hijiki::DcmgrResource::LoadBalancer.register(load_balancer_id, vifs)
       render :json => res
     end
   end

   def unregister_instances
     catch_error do
       load_balancer_id = params[:load_balancer_id]
       vifs = params[:vifs]
       res = Hijiki::DcmgrResource::LoadBalancer.unregister(load_balancer_id, vifs)
       render :json => res
     end
   end

   def poweron
     catch_error do
       load_balancer_id = params[:id]
       load_balancer = Hijiki::DcmgrResource::LoadBalancer.poweron(load_balancer_id)
       render :json => load_balancer
     end
   end

   def poweroff
     catch_error do
       load_balancer_id = params[:id]
       load_balancer = Hijiki::DcmgrResource::LoadBalancer.poweroff(load_balancer_id)
       render :json => load_balancer
     end
   end

   def update
     catch_error do
       load_balancer_id = params[:id]
       data = {
         :display_name => params[:display_name],
         :description => params[:description],
         :protocol => params[:load_balancer_protocol],
         :port => params[:load_balancer_port],
         :instance_protocol => params[:instance_protocol],
         :instance_port => params[:instance_port],
         :balance_algorithm => params[:balance_algorithm],
         :certificate_name => params[:certificate_name],
         :private_key => params[:private_key],
         :public_key => params[:public_key],
         :cookie_name => params[:cookie_name],
         :target_vifs => params[:target_vifs]
       }
       load_balancer = Hijiki::DcmgrResource::LoadBalancer.update(load_balancer_id,data)
       render :json => load_balancer
     end
  end

  def target_instances
    load_balancer_id = params[:id]
    detail = Hijiki::DcmgrResource::LoadBalancer.show(load_balancer_id)
    respond_with(detail,:to => [:json])
  end


end
