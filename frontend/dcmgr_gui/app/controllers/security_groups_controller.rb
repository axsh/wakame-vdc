class SecurityGroupsController < ApplicationController
  respond_to :json
  
  def index
  end
  
  # security_groups/show/1.json
  def list
    catch_error do
      data = {
        :start => params[:start].to_i - 1,
        :limit => params[:limit]
      }
      @security_group = Hijiki::DcmgrResource::SecurityGroup.list(data)
      respond_with(@security_group[0],:to => [:json])
    end
  end
  
  # security_groups/detail/s-000001.json
  def show
    catch_error do
      uuid = params[:id]
      @security_group = Hijiki::DcmgrResource::SecurityGroup.show(uuid)
      respond_with(@security_group,:to => [:json])
    end
  end

  def create
    catch_error do
      data = {
        :display_name => params[:display_name],
        :description => params[:description],
        :rule => params[:rule]
      }
      @security_group = Hijiki::DcmgrResource::SecurityGroup.create(data)
      render :json => @security_group
    end
  end
  
  def destroy
    catch_error do
      uuid = params[:id]
      @security_group = Hijiki::DcmgrResource::SecurityGroup.destroy(uuid)
      render :json => @security_group
    end
  end
  
  def update
    catch_error do
      uuid = params[:id]
      data = {
        :description => params[:description],
        :display_name => params[:display_name],
        :rule => params[:rule]
      }
      @security_group = Hijiki::DcmgrResource::SecurityGroup.update(uuid,data)
      render :json => @security_group
    end
  end
  
  def show_groups
    catch_error do
      @security_group = Hijiki::DcmgrResource::SecurityGroup.list
      respond_with(@security_group[0],:to => [:json])
    end
  end
  
  def total
    catch_error do
      total_resource = Hijiki::DcmgrResource::SecurityGroup.total_resource
      render :json => total_resource
    end
  end
end
