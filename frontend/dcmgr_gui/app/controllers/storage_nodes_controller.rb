class StorageNodesController < ApplicationController
  respond_to :json
  
  def index
  end
  
  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    strage_pools = DcmgrResource::StorageNode.list(data)
    respond_with(strage_pools[0], :to => [:json])
  end
  
  def show
    storage_node_id = params[:id]
    detail = DcmgrResource::StorageNode.show(storage_node_id)
    respond_with(detail,:to => [:json])
  end
  
  def show_storage_nodes
    storage_nodes = DcmgrResource::StorageNode.list
    respond_with(storage_nodes[0],:to => [:json])
  end
  
end
