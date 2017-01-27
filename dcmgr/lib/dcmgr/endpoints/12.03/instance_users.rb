# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/instance'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/instance_users' do

  get '/:iuser_id' do
    # description "Retrieve details about a vif"
    # params id, string, required
    # params vif_id, string, required
    respond_with(R::InstanceUser.new(find_uuid(params[:iuser_id])).generate)
  end

end
