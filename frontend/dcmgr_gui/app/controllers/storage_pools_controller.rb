class StoragePoolsController < ApplicationController
  respond_to :json
  
  def index
  end
  
  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    strage_pools = DcmgrResource::StoragePool.list(data)
    respond_with(strage_pools[0], :to => [:json])
  end
  
  def show
    storage_pool_id = params[:id]
    detail = DcmgrResource::StoragePool.show(storage_pool_id)
    respond_with(detail,:to => [:json])
  end
end