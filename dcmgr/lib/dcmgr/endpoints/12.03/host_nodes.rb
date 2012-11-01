# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/host_node'

Dcmgr::Endpoints::V1203::CoreAPI.namespace('/host_nodes') do
  get do
    ds = M::HostNode.dataset

    ds = datetime_range_params_filter(:created, ds)

    if params[:id]
      uuid = params[:id].split("hn-")[1]
      uuid = params[:id] if uuid.nil?
      ds = ds.filter(:uuid.like("#{uuid}%"))
    end

    if params[:node_id]
      ds = ds.filter(:node_id =>params[:node_id])
    end

    if params[:display_name]
      ds = ds.filter(:display_name =>params[:display_name])
    end

    if params[:arch]
      ds = ds.filter(:arch =>params[:arch])
    end

    if params[:hypervisor]
      ds = ds.filter(:hypervisor =>params[:hypervisor])
    end

    if params[:cpu_cores]
      ds = ds.filter(:offering_cpu_cores =>params[:cpu_cores])
    end

    if params[:memory_size]
      ds = ds.filter(:offering_memory_size =>params[:memory_size])
    end

    if params[:status]
      ds = case params[:status]
           when 'online'
             ds.online_nodes
           when 'offline'
             ds.offline_nodes
           end
    end
    collection_respond_with(ds) do |paging_ds|
      R::HostNodeCollection.new(paging_ds).generate
    end
  end

  get '/:id' do
    # description 'Show status of the host'
    # param :account_id, :string, :optional
    hn = find_by_public_uuid(:HostNode, params[:id])
    raise E::UnknownHostNode, params[:id] if hn.nil?

    respond_with(R::HostNode.new(hn).generate)
  end

  post do
    # description 'Create a new host node'
    # param :id, :string, :required
    # param :arch, :string, :required
    # param :hypervisor, :string, :required
    # param :display_name, :string, :optional
    # param :offering_cpu_cores, :int, :required
    # param :offering_memory_size, :int, :required
    params.delete(:account_id) if params[:account_id]
    hn = M::HostNode.create(params)
    respond_with(R::HostNode.new(hn).generate)
  end

  delete '/:id' do
    # description 'Delete host node'
    # param :id, :string, :required
    hn = find_by_public_uuid(:HostNode, params[:id])
    raise E::UnknownHostNode, params[:id] if hn.nil?
    hn.destroy
    respond_with({:uuid=>hn.canonical_uuid})
  end

  put '/:id' do
    # description 'Update host node'
    # param :id, :string, :required
    # param :arch, :string, :optional
    # param :hypervisor, :string, :optional
    # param :display_name, :string, :optional
    # param :offering_cpu_cores, :int, :optional
    # param :offering_memory_size, :int, :optional
    hn = find_by_public_uuid(:HostNode, params[:id])
    raise E::UnknownHostNode, params[:id] if hn.nil?

    changed = {}
    (M::HostNode.columns - [:id]).each { |c|
      if params.has_key?(c.to_s)
        changed[c] = params[c]
      end
    }

    hn.update_fields(changed, changed.keys)
    respond_with(R::HostNode.new(hn).generate)
  end
end
