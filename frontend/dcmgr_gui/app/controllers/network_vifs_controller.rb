class NetworkVifsController < ApplicationController
  respond_to :json
  include Util
  
  def index
  end
  
  def create
  end

  def destroy
  end
  
  def list
    catch_error do
      data = {
        :start => params[:start].to_i - 1,
        :limit => params[:limit]
      }
      networks = Hijiki::DcmgrResource::NetworkVif.list(data)
      respond_with(networks[0],:to => [:json])
    end
  end
  
  # GET networks/vif-24f1af4d.json
  def show
    catch_error do
      detail = Hijiki::DcmgrResource::NetworkVif.show(params[:id])
      respond_with(detail,:to => [:json])
    end
  end

  def attach
    catch_error do
      detail = Hijiki::DcmgrResource::NetworkVif.find(params[:id]).attach(params[:network_id])
      render :json => detail
    end
  end

  def detach
    catch_error do
      detail = Hijiki::DcmgrResource::NetworkVif.find(params[:id]).detach(params[:network_id])
      render :json => detail
    end
  end

  def list_monitors
    catch_error do
      detail = Hijiki::DcmgrResource::NetworkVif.find(params[:id]).list_monitors
      render :json => detail
    end
  end
  
  def add_monitor
    catch_error do
      send_params = {
        :monitors=>{}
      }
      params[:eth0_monitors].each { |idx, m|
        send_params[:monitors][idx] = m
      }
      detail = Hijiki::DcmgrResource::NetworkVif.find(params[:id]).add_monitor(send_params)
      render :json => detail
    end
  end

  def delete_monitor
    catch_error do
      detail = Hijiki::DcmgrResource::NetworkVif.find(params[:id]).delete_monitor(params[:monitor_id])
      render :json => detail
    end
  end

  def update_monitor
    catch_error do
      detail = Hijiki::DcmgrResource::NetworkVif.find(params[:id]).update_monitor(params[:monitor_id], params)
      render :json => detail
    end
  end

  def update_monitors
    catch_error do
      detail = Hijiki::DcmgrResource::NetworkVif.find(params[:id]).post('monitors', params)
      render :json => detail
    end
  end
end
