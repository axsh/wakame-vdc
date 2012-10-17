# -*- coding: utf-8 -*-

Dcmgr::Endpoints::V1112::CoreAPI.namespace '/security_groups' do
  # description 'Show lists of the security groups'
  get do
    res = select_index(:SecurityGroup, {:start => params[:start],
                         :limit => params[:limit]})
    response_to(res)
  end

  def send_reference_events(group,old_referencees,new_referencees)
    (old_referencees - new_referencees).each { |ref|
      Dcmgr.messaging.event_publish("#{ref.canonical_uuid}/referencer_removed",:args=>[group.canonical_uuid])
    }

    (new_referencees - old_referencees).each { |ref|
      Dcmgr.messaging.event_publish("#{ref.canonical_uuid}/referencer_added",:args=>[group.canonical_uuid])
    }
  end

  get '/:id' do
    # description 'Show the security group'
    g = find_by_uuid(:SecurityGroup, params[:id])
    raise E::OperationNotPermitted unless examine_owner(g)

    response_to(g.to_api_document)
  end

  post do
    # description 'Register a new security group'
    # params description, string
    # params rule, string
    M::SecurityGroup.lock!
    begin
      g = M::SecurityGroup.create(:account_id=>@account.canonical_uuid,
                                  :description=>params[:description],
                                  :rule=>params[:rule])
    rescue M::InvalidSecurityGroupRuleSyntax => e
      raise E::InvalidSecurityGroupRule, e.message
    end

    send_reference_events(g,[],g.referencees)
    response_to(g.to_api_document)
  end

  put '/:id' do
    # description "Update parameters for the security group"
    # params description, string
    # params rule, string
    g = find_by_uuid(:SecurityGroup, params[:id])

    raise E::UnknownSecurityGroup if g.nil?
    raise E::OperationNotPermitted unless examine_owner(g)

    if params[:description]
      g.description = params[:description]
    end
    if params[:rule]
      old_referencees = g.referencees_dataset.to_a
      g.rule = params[:rule]
    end

    begin
      g.save
    rescue M::InvalidSecurityGroupRuleSyntax => e
      raise E::InvalidSecurityGroupRule, e.message
    end

    res = g.to_api_document

    commit_transaction
    # refresh security group rules on host nodes.
    Dcmgr.messaging.event_publish('hva/security_group_updated', :args=>[g.canonical_uuid])
    Dcmgr.messaging.event_publish("#{g.canonical_uuid}/rules_updated")

    send_reference_events(g,old_referencees,g.referencees)

    response_to(res)
  end

  delete '/:id' do
    # description "Delete the security group"
    M::SecurityGroup.lock!
    g = find_by_uuid(:SecurityGroup, params[:id])

    raise E::UnknownSecurityGroup if g.nil?
    raise E::OperationNotPermitted unless examine_owner(g)

    send_reference_events(g,g.referencees,[])

    # raise E::OperationNotPermitted if g.instances.size > 0
    begin
      g.destroy
    rescue => e
      # logger.error(e)
      raise E::OperationNotPermitted
    end

    response_to([g.canonical_uuid])
  end
end
