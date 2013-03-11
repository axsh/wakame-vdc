# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/security_group'
require 'dcmgr/endpoints/12.03/responses/resource_label'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/security_groups' do

  def send_reference_events(group,old_referencees,new_referencees)
    (old_referencees - new_referencees).each { |ref|
      Dcmgr.messaging.event_publish("#{ref.canonical_uuid}/referencer_removed",:args=>[group.canonical_uuid])
    }

    (new_referencees - old_referencees).each { |ref|
      Dcmgr.messaging.event_publish("#{ref.canonical_uuid}/referencer_added",:args=>[group.canonical_uuid])
    }
  end

  get do
    # description 'Show lists of the security groups'
    ds = M::SecurityGroup.dataset
    if params[:account_id]
      ds = ds.filter(:account_id=>params[:account_id])
    end

    if params[:service_type]
      validate_service_type(params[:service_type])
      ds = ds.filter(:service_type=>params[:service_type])
    end

    if params[:display_name]
      ds = ds.filter(:display_name=>params[:display_name])
    end
    collection_respond_with(ds) do |paging_ds|
      R::SecurityGroupCollection.new(paging_ds).generate
    end
  end

  get '/:id' do
    # description 'Show the security group'
    g = find_by_uuid(:SecurityGroup, params[:id])
    raise E::UnknownSecurityGroup, params[:id] if g.nil?

    respond_with(R::SecurityGroup.new(g).generate)
  end

  quota 'security_group.count'
  post do
    # description 'Register a new security group'
    # params description, string
    # params rule, string
    # params display_name, string
    begin
      savedata = {
        :account_id=>@account.canonical_uuid,
        :rule=>params[:rule],
      }
      if params[:service_type]
        validate_service_type(params[:service_type])
        savedata[:service_type] = params[:service_type]
      end
      savedata[:description] = params[:description] if params[:description]
      savedata[:display_name] = params[:display_name] if params[:display_name]
      g = M::SecurityGroup.create(savedata)

      send_reference_events(g,[],g.referencees)
    rescue M::InvalidSecurityGroupRuleSyntax => e
      raise E::InvalidSecurityGroupRule, e.message
    end

    case params['labels']
    when Array
      params['labels'].each { |l|
        g.set_resource_label(l['name'], l['value'])
      }
    when Hash
      params['labels'].each { |i, l|
        g.set_resource_label(l['name'], l['value'])
      }
    end
    
    respond_with(R::SecurityGroup.new(g).generate)
  end

  namespace '/:id/labels' do
    before do
      @security_group = M::SecurityGroup[params[:id]] || raise(UnknownUUIDError, params[:id])
    end

    get '' do
      ds = @security_group.resource_labels_dataset

      if !params['name'].blank?
        ds = if params['name'] =~ /(.+)*$/
               ds.grep(:name, "#{$1}%")
             else
               ds.filter(:name=>params['name'])
             end
      end

      respond_with(R::ResourceLabelCollection.new(ds).generate)
    end
    
    get '/:name' do
      l = @security_group.label(params[:name]) || raise(UnknownResourceLabel, params[:id], params[:name])
      respond_with(R::ResourceLabel.new(l).generate)
    end

    post '/:name' do
      @security_group.set_label(params[:name], params[:value])
      respond_with(R::ResourceLabel.new(l).generate)
    end

    put '/:name' do
      l = @security_group.set_label(params[:name], params[:value])
      respond_with(R::ResourceLabel.new(l).generate)
    end
    
    delete '/:name' do
      @security_group.unset_label(params[:name])
    end
  end
  
  put '/:id' do
    # description "Update parameters for the security group"
    # params description, string
    # params rule, string
    g = find_by_uuid(:SecurityGroup, params[:id])

    raise E::UnknownSecurityGroup if g.nil?

    if params[:description]
      g.description = params[:description]
    end
    if params[:rule]
      old_referencees = g.referencees_dataset.to_a
      g.rule = params[:rule]
    end
    if params[:service_type]
      validate_service_type(params[:service_type])
      g.service_type = params[:service_type]
    end
    if params[:display_name]
      g.display_name = params[:display_name]
    end

    begin
      g.save
    rescue M::InvalidSecurityGroupRuleSyntax => e
      raise E::InvalidSecurityGroupRule, e.message
    end

    # refresh security group rules on host nodes.
    on_after_commit do
      Dcmgr.messaging.event_publish('hva/security_group_updated', :args=>[g.canonical_uuid])
      Dcmgr.messaging.event_publish("#{g.canonical_uuid}/rules_updated")

      send_reference_events(g,old_referencees,g.referencees) if params[:rule]
    end

    respond_with(R::SecurityGroup.new(g).generate)
  end

  delete '/:id' do
    #description "Delete the security group"
    g = find_by_uuid(:SecurityGroup, params[:id])

    raise E::UnknownSecurityGroup if g.nil?

    # raise E::OperationNotPermitted if g.instances.size > 0
    begin
      g.destroy
    rescue => e
      # logger.error(e)
      raise E::OperationNotPermitted
    end

    respond_with([g.canonical_uuid])
  end
end
