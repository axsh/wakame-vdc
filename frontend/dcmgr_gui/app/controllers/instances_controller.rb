class InstancesController < ApplicationController
  respond_to :json
  
  def index
  end
  
  def create
    data = {
      :image_id => params[:image_id],
      :instance_spec_id => params[:instance_spec_id],
      :host_node_id => params[:host_node_id],
      :hostname => params[:host_name],
      :user_data => params[:user_data],
      :security_groups => params[:security_groups],
      :ssh_key => params[:ssh_key],
      :display_name => params[:display_name]
    }

    if params[:vifs] and !params[:vifs].empty?
      vifs = {}
      vif_index = 0

      params[:vifs].each { |name|
        case name
        when 'none'
        when 'disconnected'
          vifs["eth#{vif_index}"] = {
            :index => vif_index,
            :network => '',
          }
        else
          vifs["eth#{vif_index}"] = {
            :index => vif_index,
            :network => name,
          }
        end

        vif_index += 1
      }

      data.merge!(:vifs => vifs)
    end

    instance = Hijiki::DcmgrResource::Instance.create(data)
    render :json => instance
  end
  
  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    instances = Hijiki::DcmgrResource::Instance.list(data)
    respond_with(instances[0],:to => [:json])
  end
  
  def show
    instance_id = params[:id]
    detail = Hijiki::DcmgrResource::Instance.show(instance_id)
    respond_with(detail,:to => [:json])
  end
  
  def terminate
    instance_ids = params[:ids]
    res = []
    instance_ids.each do |instance_id|
      res << Hijiki::DcmgrResource::Instance.destroy(instance_id)
    end
    render :json => res
  end
  
  def reboot
    instance_ids = params[:ids]
    res = []
    instance_ids.each do |instance_id|
      res << Hijiki::DcmgrResource::Instance.reboot(instance_id)
    end
    render :json => res
  end

  def start
    instance_ids = params[:ids]
    res = []
    instance_ids.each do |instance_id|
      res << Hijiki::DcmgrResource::Instance.start(instance_id)
    end
    render :json => res
  end

  def stop
    instance_ids = params[:ids]
    res = []
    instance_ids.each do |instance_id|
      res << Hijiki::DcmgrResource::Instance.stop(instance_id)
    end
    render :json => res
  end

  def backup
    instance_ids = params[:ids]
    res = []
    instance_ids.each do |instance_id|
      res << Hijiki::DcmgrResource::Instance.backup(instance_id)
    end
    render :json => res
  end

  def poweroff
    instance_ids = params[:ids]
    res = []
    instance_ids.each do |instance_id|
      res << Hijiki::DcmgrResource::Instance.poweroff(instance_id)
    end
    render :json => res
  end

  def poweron
    instance_ids = params[:ids]
    res = []
    instance_ids.each do |instance_id|
      res << Hijiki::DcmgrResource::Instance.poweron(instance_id)
    end
    render :json => res
  end
  
  def update
    instance_id = params[:id]
    data = {
      :display_name => params[:display_name],
      :security_groups => params[:security_groups]
    }
    instance = Hijiki::DcmgrResource::Instance.update(instance_id,data)
    render :json => instance
  end
  
  def total
   all_resource_count = Hijiki::DcmgrResource::Instance.total_resource
   all_resources = Hijiki::DcmgrResource::Instance.find(:all,:params => {:start => 0, :limit => all_resource_count})
   resources = all_resources[0].results
   terminated_resource_count = Hijiki::DcmgrResource::Instance.get_resource_state_count(resources, 'terminated')
   total = all_resource_count - terminated_resource_count
   render :json => total
  end

  def show_instances
    instances = Hijiki::DcmgrResource::Instance.list
    respond_with(instances[0],:to => [:json])
  end
end
