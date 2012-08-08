class MachineImagesController < ApplicationController
  respond_to :json
  
  def index
  end
  
  def show
    catch_error do
      image_id = params[:id]
      detail = Hijiki::DcmgrResource::Image.show(image_id)
      respond_with(detail,:to => [:json])
    end
  end
    
  def list
    catch_error do
      data = {
        :start => params[:start].to_i - 1,
        :limit => params[:limit]
      }
      image = Hijiki::DcmgrResource::Image.list(data)
      respond_with(image[0],:to => [:json])
    end
  end
  
  def update
    catch_error do
      image_id = params[:id]
      data = {
        :display_name => params[:display_name],
        :description => params[:description]
      }
      image = Hijiki::DcmgrResource::Image.update(image_id,data)
      render :json => image
    end
  end

  def destroy
    catch_error do
      image_id = params[:id]
      image = Hijiki::DcmgrResource::Image.destroy(image_id)
      render :json => image
    end
  end

  def total
    catch_error do
      total_resource = Hijiki::DcmgrResource::Image.total_resource
      render :json => total_resource
    end
  end
end
