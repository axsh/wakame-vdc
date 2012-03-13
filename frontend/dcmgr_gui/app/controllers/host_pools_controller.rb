class HostPoolsController < ApplicationController
  respond_to :json
  
  def index
  end
  
  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    host_pools = DcmgrResource::HostPool.list(data)
    logger.debug(host_pools.inspect)  
    respond_with(host_pools[0], :to => [:json])
  end
  
  def show
    host_pool_id = params[:id]
    detail = DcmgrResource::HostPool.show(host_pool_id)
    respond_with(detail,:to => [:json])
  end
  
  def show_host_pools
    host_pools = DcmgrResource::HostPool.list
    respond_with(host_pools[0],:to => [:json])
  end

  def expand_hash(h)
    own_str = ''
    h.each{ |h,v| if v.class == Hash then
                    v_str = expand_hash(v)
                  else
                    v_str = v
                  end;
                  if own_str == '' then
                    own_str = "#{h} => #{v_str}"
                  else
                    own_str = ownstr + ",#{h} => #{v_str}"
                  end}
    own_str = "{ %s }" % own_str
  end 
end
