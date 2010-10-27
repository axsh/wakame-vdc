class ImagesController < ApplicationController
  respond_to :json
  
  def index
  end
  
  # images/show/1.json
  def show
    image_id = params[:id]
    detail = Frontend::Models::DcmgrResource::Image.show(image_id)
    respond_with(detail,:to => [:json])
  end

    
  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    image = Frontend::Models::DcmgrResource::Image.list(data)
    respond_with(image[0],:to => [:json])
  end
end