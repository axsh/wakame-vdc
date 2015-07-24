# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/virtual_data_center'
require 'yaml'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/virtual_data_centers' do
  VDC_INSTANCE_TYPE = ['docker', 'openstack'].freeze
  VDC_SPEC  = ['small', 'medium', 'large'].freeze

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
    raise E::UnknownVirtualDataCenter, params['id'] if vdc.nil?

    respond_with(R::VirtualDataCenter.new(vdc).generate)
  end

  # Create virtual_data_center
  # param :type, string, required
  # param :spec: string, required
  # param :spec_file: string, optional
  post do
    raise E::InvalidParameter, 'type' unless VDC_INSTANCE_TYPE.include? params['type']
    raise E::InvalidParameter, 'spec' unless VDC_SPEC.include? params['spec']

    if params['spec_file']
      begin
        spec_file = YAML.load(params['spec_file'])
      rescue Psych::SyntaxError
        raise E::InvalidParameter, 'spec_file'
      end
    end
    # Get instance spec parameter from spec file
    # vdc_spec = Dcmgr::SpecConvertor::VirtualDataCenter.new
    # vdc_spec.convert

    vdc = M::VirtualDataCenter.entry_new(@account)
    vdc.add_virtual_data_center_spec(spec_file)

    instance_params = generate_instance_params(params['type'], params['spec'], spec_file)

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
    vdc = find_by_uuid(:VirtualDataCenter, params[:id])
    raise E::UnknownVirtualDataCenter, params['id'] if vdc.nil?

    account_id = @account.canonical_uuid
    vdc.vdc_instances.each do |instance|
      request_forward do
        header('X-VDC-Account-UUID', account_id)
        delete("/instances/#{instance.canonical_uuid}.yml")
      end.last_response
    end
    vdc.destroy

    respond_with([vdc.canonical_uuid])
  end

  def generate_instance_params(type, spec, spec_file)
    raise ArgumentError, "The params parameter must be a String. Got '#{type.class}'" if !type.is_a?(String)
    raise ArgumentError, "The params parameter must be a String. Got '#{spec.class}'" if !spec.is_a?(String) 
    raise ArgumentError, "The params parameter must be a Hash. Got '#{spec_file.class}'" if !spec_file.is_a?(Hash)

    instance_spec = spec_file['instance_spec'][spec]
    vdc_spec = spec_file['vdc_spec'].select {|k,v|
      v['instance_type'] == type && v['instance_spec'] == spec
    }

    instance_params = []
    vdc_spec.each { |k,v|
      instance_params << v.merge(instance_spec)
    }

    instance_params
  end
end
