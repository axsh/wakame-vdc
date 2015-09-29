# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/virtual_data_center_spec'
require 'yaml'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/virtual_data_center_specs' do

  # show list of virtual_data_center_specs
  get do
    ds = M::VirtualDataCenterSpec.dataset
    ds = datetime_range_params_filter(:created, ds)
    ds = datetime_range_params_filter(:deleted, ds)

    collection_respond_with(ds) do |paging_ds|
      R::VirtualDataCenterSpecCollection.new(paging_ds).generate
    end
  end

  # show detail of virtual_data_center_spec
  # param :id, string, required
  get '/:id' do
    vdcs = find_by_uuid(:VirtualDataCenterSpec, params['id'])
    raise E::UnknownVirtualDataCenterSpec, params['id'] if vdcs.nil?

    respond_with(R::VirtualDataCenterSpec.new(vdcs).generate)
  end

  # Create virtual_data_center_spec
  # param :file, string, required
  post do

    vdcs = M::VirtualDataCenterSpec.entry_new(@account) do |vdcs|
      begin
        file = vdcs.load(params['file'])
        vdcs.check_spec_file_format(file)

        vdcs.name = file['vdc_name']
        vdcs.file = file
      rescue => e
        raise E::InvalidParameter, e
      end
    end

    respond_with(R::VirtualDataCenterSpec.new(vdcs).generate)
  end

  # Update virtual_data_center_spec
  # param :id, string, required
  # param :file, string, options
  put '/:id' do
    vdcs = find_by_uuid(:VirtualDataCenterSpec, params['id'])
    raise E::UnknownVirtualDataCenterSpec, params['id'] if vdcs.nil?

    if params['file']
      begin
        file = vdcs.load(params['file'])
        vdcs.check_spec_file_format(file)
        vdcs.name = file['vdc_name']
        vdcs.file = file
        vdcs.save_changes
      rescue => e
        raise E::InvalidParameter, e
      end
    end

    respond_with(R::VirtualDataCenterSpec.new(vdcs).generate)
  end

  # Delete virtual_data_center_spec
  # param :id, string, required
  delete '/:id' do
    vdcs = find_by_uuid(:VirtualDataCenterSpec, params['id'])
    raise E::UnknownVirtualDataCenterSpec, params['id'] if vdcs.nil?

    vdcs.destroy

    respond_with([vdcs.canonical_uuid])
  end
end
