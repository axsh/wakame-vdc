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
    raise E::UndefinedRequiredParameter, 'vdc_spec' if params['vdc_spec'].nil?

    vdc = M::VirtualDataCenter.entry_new(@account) do |vdc|
      vdcs = find_by_uuid(:VirtualDataCenterSpec, params['vdc_spec'])
      vdc.virtual_data_center_spec_id = vdcs.id
    end

    instance_params = vdc.spec.generate_instance_params
    account_id = @account.canonical_uuid

    # Create instances
    instance_params.each { |instance_param|
      res = request_forward do
        header('X-VDC-Account-UUID', account_id)
        post("/instances.yml", instance_param)
      end.last_response
      instance = YAML.load(res.body)

      vdc.add_instance find_by_uuid(:Instance, instance[:id])
    }

    # Create security groups
    security_group_params = vdc.spec.file['security_groups']

    # We create all security groups first and set their rules later.
    # That is because rules might include other groups' UUIDs and we
    # don't know what they are until they're created.
    security_group_params.each { |secg_name, secg_param|
      display_name = "#{vdc.canonical_uuid} #{secg_name}"

      res = request_forward do
        header('X-VDC-Account-UUID', account_id)
        post("/security_groups", display_name: display_name)
      end.last_response
      secg_id = JSON.load(res.body)['id']

      secg = find_by_uuid(:SecurityGroup, secg_id)

      secg.name_in_virtual_data_center_spec = secg_name
      secg.save_changes

      vdc.add_security_group secg

      secg_param['id'] = secg_id
    }

    # Now we set all the rules
    security_group_params.each { |secg_name, secg_param|
      security_group_params.keys.each { |secg_name2|
        #TODO: Deal with the possibility of secg_names being substrings of each other
        secg_param['rules'].gsub!(/#{secg_name2}/, security_group_params[secg_name2]['id'])
      }

      #TODO: Make sure these internal requests succeed
      res = request_forward do
        header('X-VDC-Account-UUID', account_id)
        put("/security_groups/#{secg_param['id']}", rule: secg_param['rules'])
      end
    }

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
        delete("/instances/#{instance.canonical_uuid}")
      end
    end

    vdc.security_groups.each do |security_group|
      request_forward do
        header('X-VDC-Account-UUID', account_id)
        delete("/security_groups/#{security_group.canonical_uuid}")
      end
    end

    vdc.destroy

    respond_with([vdc.canonical_uuid])
  end
end
