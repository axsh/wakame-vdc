class StorageNodesController < ApplicationController
  respond_to :json
  
  def index
  end
  
  def list
    catch_error do
      data = {
        :start => params[:start].to_i - 1,
        :limit => params[:limit]
      }
      strage_pools = Hijiki::DcmgrResource::StorageNode.list(data)
      respond_with(strage_pools[0], :to => [:json])
    end
  end
  
  def show
    catch_error do
      storage_node_id = params[:id]
      detail = Hijiki::DcmgrResource::StorageNode.show(storage_node_id)
      respond_with(detail,:to => [:json])
    end
  end
  
  def show_storage_nodes
    catch_error do
      storage_nodes = Hijiki::DcmgrResource::StorageNode.list
      respond_with(storage_nodes[0],:to => [:json])
    end
  end
  
end
