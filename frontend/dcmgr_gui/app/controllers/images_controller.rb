class ImagesController < ApplicationController
  respond_to :json
  
  def index
  end
  
  # images/show/1.json
  def show
    image_id = params[:id]
    detail = DcmgrResource::Image.show(image_id)
    respond_with(detail,:to => [:json])
  end

    
  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    image = DcmgrResource::Image.list(data)
    respond_with(image[0],:to => [:json])
  end
  
  def total
   total_resource = DcmgrResource::Image.total_resource
   render :json => total_resource
  end
end