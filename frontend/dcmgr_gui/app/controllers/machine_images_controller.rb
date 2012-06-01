class MachineImagesController < ApplicationController
  respond_to :json
  
  def index
  end
  
  def show
    image_id = params[:id]
    detail = Hijiki::DcmgrResource::Image.show(image_id)
    respond_with(detail,:to => [:json])
  end

    
  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    image = Hijiki::DcmgrResource::Image.list(data)
    respond_with(image[0],:to => [:json])
  end
  
  def total
   total_resource = Hijiki::DcmgrResource::Image.total_resource
   render :json => total_resource
  end
end
