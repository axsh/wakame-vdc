# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/physical_network'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/physical_networks' do
  get do
    ds = M::PhysicalNetwork.dataset
    if params[:name]
      ds = ds.filter(:name=>params[:name])
    end

    if params[:account_id]
      # TODO: filter VLAN networks owned by the account_id.
    end

    ds = datetime_range_params_filter(:created, ds)
    
    collection_respond_with(ds) do |paging_ds|
      R::PhysicalNetworkCollection.new(paging_ds).generate
    end
  end

  get '/:id' do
    pn = find_by_uuid(:PhysicalNetwork, params[:id])

    respond_with(R::PhysicalNetwork.new(pn).generate)
  end

  post do
    begin
      pn = M::PhysicalNetwork.create(:name=>params[:name],
                                     :bridge_type => params[:bridge_type] || :bridge,
                                     :description=>params[:description])
    rescue => e
      raise E::DatabaseError, e.message
    end

    respond_with(R::PhysicalNetwork.new(pn).generate)
  end

  delete '/:id' do
    pn = find_by_uuid(:PhysicalNetwork, params[:id])
    pn.destroy

    respond_with([pn.canonical_uuid])
  end

  put '/:id' do
    pn = find_by_uuid(:PhysicalNetwork, params[:id])
    
    changed = {}
    (M::PhysicalNetwork.columns - [:id]).each { |c|
      if params.has_key?(c.to_s)
        changed[c] = params[c]
      end
    }
    pn.update_fields(changed, changed.keys)

    respond_with(R::PhysicalNetwork.new(pn).generate)
  end
end
