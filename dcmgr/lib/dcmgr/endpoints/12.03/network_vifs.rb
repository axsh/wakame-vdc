# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/network'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/network_vifs' do

  def vif_account_id(vif)
    return vif.network.account_id if vif.network
    return vif.instance.account_id if vif.instance

    raise(E::UnknownUUIDResource, vif_id.to_s)
  end

  def find_vif_uuid(vif_id)
    vif = M::NetworkVif[vif_id] || raise(E::UnknownNetworkVif, vif_id)

    if @account && (@account.canonical_uuid.nil? || vif_account_id(vif) != @account.canonical_uuid)
      raise(E::UnknownUUIDResource, vif_id.to_s)
    end

    vif
  end

  get '/:vif_id' do
    # description "Retrieve details about a vif"
    # params id, string, required
    # params vif_id, string, required
    respond_with(R::NetworkVif.new(find_vif_uuid(params[:vif_id])).generate)
  end

end
