class VolumesController < ApplicationController
  respond_to :json
  include Util
  
  def index
  end
  
  def create
    snapshot_ids = params[:ids]
    if snapshot_ids
      response = []
      snapshot_ids.each do |snapshot_id|
        data = {
          :snapshot_id => snapshot_id
        }
        response << DcmgrResource::Volume.create(data)
      end
      render :json => response
    else
      # Convert to MB
      size = case params[:unit]
             when 'gb'
               params[:size].to_i * 1024
             when 'tb'
               params[:size].to_i * 1024 * 1024
             end
      
      storage_pool_id = params[:storage_pool_id] #option
      
      data = {
        :volume_size => size,
        :storage_pool_id => storage_pool_id
      }
      
      @volume = DcmgrResource::Volume.create(data)

      render :json => @volume
    end
  end
  
  def destroy
    volume_ids = params[:ids]
    response = []
    volume_ids.each do |volume_id|
      response << DcmgrResource::Volume.destroy(volume_id)
    end
    render :json => response
  end
  
  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    volumes = DcmgrResource::Volume.list(data)
    respond_with(volumes[0],:to => [:json])
  end
  
  # GET volumes/vol-24f1af4d.json
  def show
    volume_id = params[:id]
    detail = DcmgrResource::Volume.show(volume_id)
    respond_with(detail,:to => [:json])
  end

  def attach
    volume_id = params[:volume_id]
    instance_id = params[:instance_id]
    response = DcmgrResource::Volume.attach(volume_id, instance_id)
    render :json => response
  end

  def detach
    volume_ids = params[:ids]
    response = []
    volume_ids.each do |volume_id|
      response << DcmgrResource::Volume.detach(volume_id)
    end
    render :json => response
  end
  
  def total
    total_resource = DcmgrResource::Volume.total_resource
    render :json => total_resource
  end
end
