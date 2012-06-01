class HostNodesController < ApplicationController
  respond_to :json
  
  def index
  end
  
  def list
    data = {
      :start => params[:start].to_i - 1,
      :limit => params[:limit]
    }
    host_nodes = Hijiki::DcmgrResource::HostNode.list(data)
    logger.debug(host_nodes.inspect)  
    respond_with(host_nodes[0], :to => [:json])
  end
  
  def show
    host_node_id = params[:id]
    detail = Hijiki::DcmgrResource::HostNode.show(host_node_id)
    respond_with(detail,:to => [:json])
  end
  
  def show_host_nodes
    host_nodes = Hijiki::DcmgrResource::HostNode.list
    respond_with(host_nodes[0],:to => [:json])
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
