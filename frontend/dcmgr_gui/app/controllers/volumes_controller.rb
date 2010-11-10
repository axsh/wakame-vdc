class VolumesController < ApplicationController
  respond_to :json
  include Util
  
  def index
  end
  
  # POST volumes/create.json
  def create
    snapshot_ids = params[:ids]
    if snapshot_ids
      response = []
      snapshot_ids.each do |snapshot_id|
        data = {
          :snapshot_id => snapshot_id
        }
        response << Frontend::Models::DcmgrResource::Volume.create(data)
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
      
      # snapshot_id = params[:snapshot_id] #option
      # storage_pool_id = params[:storage_pool_id] #option
      
      data = {
        :volume_size => size,
        # :storage_pool_id => storage_pool_id,
        # :snapshot_id => snapshot_id
      }
      
      @volume = Frontend::Models::DcmgrResource::Volume.create(data)

      render :json => @volume
    end
  end
  
  # DELETE volumes/delete.json
  def delete
    volume_ids = params[:ids]
    response = []
    volume_ids.each do |volume_id|
      response << Frontend::Models::DcmgrResource::Volume.destroy(volume_id)
    end
    render :json => response
  end
  
  # GET volumes.json
  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    volumes = Frontend::Models::DcmgrResource::Volume.list(data)
    respond_with(volumes[0],:to => [:json])
  end
  
  # GET volumes/vol-24f1af4d.json
  def show
    volume_id = params[:id]
    detail = Frontend::Models::DcmgrResource::Volume.show(volume_id)
    detail["size"] = convert_from_mb_to_gb(detail["size"]).to_s + 'GB'
    respond_with(detail,:to => [:json])
  end

  def attach
    volume_id = params[:volume_id]
    instance_id = params[:instance_id]
    response = Frontend::Models::DcmgrResource::Volume.attach(volume_id, instance_id)
    render :json => response
  end

  def detach
    volume_ids = params[:ids]
    response = []
    volume_ids.each do |volume_id|
      response << Frontend::Models::DcmgrResource::Volume.detach(volume_id)
    end
    render :json => response
  end
end
