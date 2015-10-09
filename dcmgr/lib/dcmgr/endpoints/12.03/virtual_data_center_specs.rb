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

    respond_with(R::VirtualDataCenterSpec.new(vdcs).generate)
  end

  # Create virtual_data_center_spec
  # param :file, string, required
  post do
    raise E::UndefinedRequiredParameter, 'file' if params['file'].nil?

    begin
      vdcs = M::VirtualDataCenterSpec.entry_new(@account) do |spec|
        case file = M::VirtualDataCenterSpec.load(params['file'])
        when Hash
          spec.name = file['vdc_name']
          spec.file = file
        else
          raise E::InvalidParameter, params['file']
        end
      end
    rescue M::VirtualDataCenterSpec::YamlLoadError, Sequel::ValidationFailed => e
      raise E::InvalidVirtualDataCenterSpec, e.message
    end

    respond_with(R::VirtualDataCenterSpec.new(vdcs).generate)
  end

  # Update virtual_data_center_spec
  # param :id, string, required
  # param :file, string, options
  put '/:id' do
    vdcs = find_by_uuid_alives(:VirtualDataCenterSpec, params['id'])

    if params['file']
      begin
        case file = M::VirtualDataCenterSpec.load(params['file'])
        when Hash
          vdcs.name = file['vdc_name']
          vdcs.file = file
          vdcs.save_changes
        else
          raise E::InvalidParameter, params['file']
        end
      rescue M::VirtualDataCenterSpec::YamlLoadError, Sequel::ValidationFailed => e
        raise E::InvalidVirtualDataCenterSpec, e.message
      end
    end

    respond_with(R::VirtualDataCenterSpec.new(vdcs).generate)
  end

  # Delete virtual_data_center_spec
  # param :id, string, required
  delete '/:id' do
    vdcs = find_by_uuid_alives(:VirtualDataCenterSpec, params['id'])

    vdcs.destroy

    respond_with([vdcs.canonical_uuid])
  end
end
