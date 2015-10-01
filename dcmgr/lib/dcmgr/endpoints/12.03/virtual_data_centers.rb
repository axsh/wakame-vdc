# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/virtual_data_center'
require 'yaml'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/virtual_data_centers' do

  # Show list of virtual_data_centers
  get do
    ds = M::VirtualDataCenter.dataset
    ds = datetime_range_params_filter(:created, ds)
    ds = datetime_range_params_filter(:deleted, ds)

    collection_respond_with(ds) do |paging_ds|
      R::VirtualDataCenterCollection.new(paging_ds).generate
    end
  end

  # Show detail of virtual_data_center
  # param :id, string, requried
  get '/:id' do
    vdc = find_by_uuid(:VirtualDataCenter, params['id'])

    respond_with(R::VirtualDataCenter.new(vdc).generate)
  end

  # Create virtual_data_center
  # param :vdc_spec, string, required
  post do
    vdc = M::VirtualDataCenter.entry_new(@account) do |vdc|
      case M::VirtualDataCenterSpec.load(params['vdc_spec'])
      when String
        vdcs = M::VirtualDataCenterSpec[params['vdc_spec']]
      when Hash
        vdcs = M::VirtualDataCenterSpec.entry_new(@account, params['vdc_spec'])
      else
        raise E::InvalidParameter, params['vdc_spec']
      end
      vdc.virtual_data_center_spec_id = vdcs.id
    end

    instance_params = vdc.spec.generate_instance_params
    account_id = @account.canonical_uuid
    instances = []

    instance_params.each { |instance_param|
      res = request_forward do
        header('X-VDC-Account-UUID', account_id)
        post("/instances.yml", instance_param)
      end.last_response
      instance = YAML.load(res.body)
      instances << find_by_uuid(:Instance, instance[:id]).id
    }
    vdc.add_virtual_data_center_instance(instances)
    
    respond_with(R::VirtualDataCenter.new(vdc).generate)
  end

  # Delete virtual_data_center
  # param :id, string, requried
  delete '/:id' do
    vdc = find_by_uuid_alives(:VirtualDataCenter, params[:id])

    account_id = @account.canonical_uuid
    vdc.instances.each do |instance|
      request_forward do
        header('X-VDC-Account-UUID', account_id)
        delete("/instances/#{instance.canonical_uuid}.yml")
      end.last_response
    end
    vdc.destroy

    respond_with([vdc.canonical_uuid])
  end
end
