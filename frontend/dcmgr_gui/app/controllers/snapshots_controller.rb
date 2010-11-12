class SnapshotsController < ApplicationController
  respond_to :json
  include Util

  def index
  end

  def create
    volume_ids = params[:ids]
    response = []
    volume_ids.each do |volume_id|
      data = {
        :volume_id => volume_id
      }
      response << Frontend::Models::DcmgrResource::VolumeSnapshot.create(data)
    end
    render :json => response
  end

  def delete
    snapshot_ids = params[:ids]
    response = []
    snapshot_ids.each do |snapshot_id|
      response << Frontend::Models::DcmgrResource::VolumeSnapshot.delete(snapshot_id)
    end
    render :json => response
  end

  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    snapshots = Frontend::Models::DcmgrResource::VolumeSnapshot.list(data)
    respond_with(snapshots[0], :to => [:json])
  end

  def show
    snapshot_id = params[:id]
    detail = Frontend::Models::DcmgrResource::VolumeSnapshot.show(snapshot_id)
    detail["size"] = convert_from_mb_to_gb(detail["size"]).to_s + 'GB'
    respond_with(detail,:to => [:json])
  end
  
  def total
   total_resource = Frontend::Models::DcmgrResource::VolumeSnapshot.total_resource
   render :json => total_resource
  end
end
