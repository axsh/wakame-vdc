# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/host_node_group'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/host_node_groups' do
  get do
    # description 'Show lists of the host node groups'
    ds = Dcmgr::Tags::HostNodeGroup.dataset
    if params[:account_id]
      ds = ds.filter(:account_id=>params[:account_id])
    end
    
    if params[:service_type]
      validate_service_type(params[:service_type])
      ds = ds.filter(:service_type=>params[:service_type])
    end
    
    if params[:name]
      ds = ds.filter(:name=>params[:name])
    end
    
    collection_respond_with(ds) do |paging_ds|
      R::HostNodeGroupCollection.new(paging_ds).generate
    end
  end
  
  get '/:id' do
    # description 'Show the host node group'
    g = Dcmgr::Tags::HostNodeGroup[params[:id]]
    raise E::UnknownUUIDResource, params[:id] if g.nil?

    respond_with(R::HostNodeGroup.new(g).generate)
  end
  
  post do
    # description 'Create a new host node group'
    # params attributes, string
    # params name, string
    raise E::UndefinedRequiredParameter, "Missing required parameter: name" unless params[:name]
    
    savedata = {
      :account_id=>@account.canonical_uuid,
      :name=>params[:name]
    }
    savedata[:attributes] = params[:attributes] if params[:attributes]
    if params[:service_type]
      validate_service_type(params[:service_type])
      savedata[:service_type] = params[:service_type]
    end
    
    g = Dcmgr::Tags::HostNodeGroup.create(savedata)
    respond_with(R::HostNodeGroup.new(g).generate)
  end
  
  delete '/:id' do
    Dcmgr::Tags.constants.each {|c| Dcmgr::Tags.const_get(c) }
    begin
      tag = M::Taggable.find(params[:id])
    rescue
      raise E::UnknownUUIDResource, params[:id]
    end
    raise E::UnknownUUIDResource, params[:id] unless tag.is_a? M::Tag
    tag.remove_all_mapped_uuids
    tag.destroy
    response_to([tag.canonical_uuid])
  end
  
  put '/:id' do
    # description 'Updates a host node group'
    # param :id, string, :required
    # param :host_nodes, string|array, :optional
    # param :name, string, :optional
    g = Dcmgr::Tags::HostNodeGroup[params[:id]]
    raise E::UnknownUUIDResource, params[:id] if g.nil?
    
    
    if params[:name]
      raise E::InvalidParameter, "name should be a 'String'. Got '#{params[:name].class}' instead."
      g[:name] = params[:name]
    end
    
    if params[:host_nodes] == "" || params[:host_nodes] == []
      g.remove_all_mapped_uuids
    elsif params[:host_nodes].is_a?(Array) || params[:host_nodes].is_a?(String)
      host_node_uuids = params[:host_nodes]
      host_node_uuids = [host_node_uuids] if host_node_uuids.is_a?(String)
      
      # Check if there are any invalid uuids in the request
      M.constants.each {|c| M.const_get(c) }
      host_node_uuids.each { |uuid|
        object = M::Taggable.find(uuid)
        raise UnknownUUIDResource, "Unknown or inacceptable resource: '#{uuid}'" unless g.accept_mapping?(object)
      }
      
      old_mapped_uuids = g.mapped_uuids.map { |mapping| mapping[:uuid] }
      
      # Delete old uuids
      (old_mapped_uuids - host_node_uuids).each { |uuid|
        mapping = M::TagMapping.find(
          :tag_id => g.id,
          :uuid   => uuid
        )
        
        mapping.destroy unless mapping.nil?
      }
      
      # Add new uuids
      (host_node_uuids - old_mapped_uuids).each { |uuid|
        M::TagMapping.create(
          :tag_id => g.id,
          :uuid   => uuid
        )
      }
    else
      raise E::InvalidParameter, "host_nodes should be a 'String' or 'Array'. Got '#{params[:host_nodes].class}' instead." unless params[:host_nodes].nil?
    end
    
    g.save_changes

    commit_transaction
    respond_with(R::HostNodeGroup.new(g).generate)
  end
  
end
