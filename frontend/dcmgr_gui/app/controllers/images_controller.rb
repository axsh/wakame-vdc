class ImagesController < ApplicationController
  respond_to :json
  
  def index
  end
  
  # images/show/1.json
  def show
    json = Frontend::Models::DcmgrResource::Mock.load('images/list')
    @images = JSON.load(json)

    page = params[:id].to_i
    limit = 10
    from = ((page -1) * limit).to_i
    to = (from + limit -1).to_i
    respond_with(@images[from..to],:to => [:json])
  end
  
  # images/detail/wmi-96d780f4.json
  def detail
    wmi_id = params[:id]
    json = Frontend::Models::DcmgrResource::Mock.load('images/details')
    @detail = JSON.load(json)
    respond_with(@detail[wmi_id],:to => [:json])
  end
end
