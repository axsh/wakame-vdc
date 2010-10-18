class VolumesController < ApplicationController
  respond_to :json
  
  def index
  end
  
  # POST volumes/create.json
  def create
    @volume = Frontend::Models::DcmgrResource::Volume.create
    size = params[:size]
    snapshot = params[:snapshot]
    
    render :json => @volume
  end
  
  # DELETE volumes/delete.json
  def delete
    account_id = current_account.uuid
    volume_ids = params[:ids]
    response = []
    volume_ids.each do |volume_id|
      response << Frontend::Models::DcmgrResource::Volume.destroy(account_id,volume_id)
    end
    render :json => response
  end
  
  # GET volumes/show/1.json
  def show
    json = Frontend::Models::DcmgrResource::Mock.load('volumes/list')
    @volumes = JSON.load(json)

    page = params[:id].to_i
    limit = 10
    from = ((page -1) * limit).to_i
    to = (from + limit -1).to_i
    respond_with(@volumes[from..to],:to => [:json])
    
  end
  
  # GET volumes/detail/vol-24f1af4d.json
  def detail
    volume_id = params[:id]
    json = Frontend::Models::DcmgrResource::Mock.load('volumes/details')
    @detail = JSON.load(json)
    respond_with(@detail[volume_id],:to => [:json])
  end
end
