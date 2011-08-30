class SnapshotsController < ApplicationController
  respond_to :json
  include Util

  def index
  end

  def create
    volume_ids = params[:ids]
    destination = params[:destination]
    res = []
    volume_ids.each do |volume_id|
      data = {
        :volume_id => volume_id,
        :destination => destination
      }
      res << DcmgrResource::VolumeSnapshot.create(data)
    end
    render :json => res
  end

  def destroy
    snapshot_ids = params[:ids]
    res = []
    snapshot_ids.each do |snapshot_id|
      res << DcmgrResource::VolumeSnapshot.delete(snapshot_id)
    end
    render :json => res
  end

  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    snapshots = DcmgrResource::VolumeSnapshot.list(data)
    respond_with(snapshots[0], :to => [:json])
  end

  def show
    snapshot_id = params[:id]
    detail = DcmgrResource::VolumeSnapshot.show(snapshot_id)
    respond_with(detail,:to => [:json])
  end
  
  def total
    all_resource_count = DcmgrResource::VolumeSnapshot.total_resource
    all_resources = DcmgrResource::VolumeSnapshot.find(:all,:params => {:start => 0, :limit => all_resource_count})
    resources = all_resources[0].results
    deleted_resource_count = DcmgrResource::VolumeSnapshot.get_resource_state_count(resources, 'deleted')
    total = all_resource_count - deleted_resource_count
    render :json => total
  end
  
  def upload_destination
    destinations = DcmgrResource::VolumeSnapshot.upload_destination
    render :json => destinations[0]
  end
end
