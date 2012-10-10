# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/dc_network'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/dc_networks' do
  get do
    ds = M::DcNetwork.dataset
    if params[:name]
      ds = ds.filter(:name=>params[:name])
    end

    if params[:account_id]
      # TODO: filter VLAN networks owned by the account_id.
    end

    ds = datetime_range_params_filter(:created, ds)

    collection_respond_with(ds) do |paging_ds|
      R::DcNetworkCollection.new(paging_ds).generate
    end
  end

  get '/:id' do
    dcn = find_by_public_uuid(:DcNetwork, params[:id])

    respond_with(R::DcNetwork.new(dcn).generate)
  end

  post do
    begin
      dcn = M::DcNetwork.create(:name=>params[:name],
                                :description=>params[:description])
    rescue => e
      raise E::DatabaseError, e.message
    end

    respond_with(R::DcNetwork.new(dcn).generate)
  end

  delete '/:id' do
    dcn = find_by_public_uuid(:DcNetwork, params[:id])
    dcn.destroy

    respond_with([dcn.canonical_uuid])
  end

  put '/:id' do
    dcn = find_by_public_uuid(:DcNetwork, params[:id])

    changed = {}
    (M::DcNetwork.columns - [:id]).each { |c|
      if params.has_key?(c.to_s)
        changed[c] = params[c]
      end
    }
    dcn.update_fields(changed, changed.keys)

    respond_with(R::DcNetwork.new(dcn).generate)
  end

  get '/:id/offering_modes' do
    dcn = find_by_public_uuid(:DcNetwork, params[:id])
    respond_with(dcn.offering_network_modes || [])
  end

  # modify offering network mode list
  put '/:id/offering_modes/add' do
    dcn = find_by_public_uuid(:DcNetwork, params[:id])
    modelst = case params[:mode]
              when String
                params[:mode].split(',')
              when Array
                params[:mode]
              end

    modelst.each { |i|
      dcn.offering_network_modes << i
    }
    modelst.uniq!
    dcn.update_only({:offering_network_modes=>dcn.offering_network_modes}, :offering_network_modes)
    respond_with(dcn.offering_network_modes || [])
  end

  put '/:id/offering_modes/delete' do
    dcn = find_by_public_uuid(:DcNetwork, params[:id])
    modelst = case params[:mode]
              when String
                params[:mode].split(',')
              when Array
                params[:mode]
              end

    modelst.each { |i|
      dcn.offering_network_modes.delete(i)
    }
    modelst.uniq!
    dcn.update_only({:offering_network_modes=>dcn.offering_network_modes}, :offering_network_modes)
    respond_with(dcn.offering_network_modes || [])
  end
end
