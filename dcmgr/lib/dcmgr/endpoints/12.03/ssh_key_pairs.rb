# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/ssh_key_pair'
require 'sshkey'
Dcmgr::Endpoints::V1203::CoreAPI.namespace '/ssh_key_pairs' do
  register V1203::Helpers::ResourceLabel
  enable_resource_label(M::SshKeyPair)

  desc "List the ssh key pairs currently in the database."
  param :start, :Integer,
                desc: "The index to start listing from."
  param :limit, :Integer,
                desc: "The maximum amount of ssh_key_pairs to list."
  param :service_type, :String,
                in: Dcmgr::Configurations.dcmgr.service_types,
                desc: "Show only ssh key pairs of this service type."
  param :display_name, :String,
                desc: "Show only ssh key pairs with this display name."
  get do
    ds = M::SshKeyPair.dataset.filter(account_id: @account.canonical_uuid)

    ds = datetime_range_params_filter(:created, ds)
    ds = datetime_range_params_filter(:deleted, ds)

    if params[:service_type]
      validate_service_type(params[:service_type])
      ds = ds.filter(:service_type=>params[:service_type])
    end

    if params[:display_name]
      ds = ds.filter(:display_name=>params[:display_name])
    end

    ds = ds.alives

    collection_respond_with(ds) do |paging_ds|
      R::SshKeyPairCollection.new(paging_ds).generate
    end
  end

  desc "Retrieve details about a single ssh key pair"
  param :id, :String,
             required: true,
             desc: "The UUID of the ssh key pair to describe."
  get '/:id' do
    ssh = find_by_uuid(:SshKeyPair, params[:id])
    raise UnknownSshKeyPair, params[:id] if ssh.nil?

    respond_with(R::SshKeyPair.new(ssh).generate)
  end

  quota 'ssh_key_pair.count'
  post do
    # description "Create ssh key pair information"
    # params :display_name optional
    private_key = nil
    ssh = M::SshKeyPair.entry_new(@account) do |s|

      if params[:public_key] && !params[:public_key].empty?
        unless SSHKey.valid_ssh_public_key?(params[:public_key])
          raise InvalidSshPublicKey, params[:public_key]
        end
        s.public_key = params[:public_key]

        # Calculate ssh key fingerprint
        s.finger_print = SSHKey.fingerprint(params[:public_key])
      else
        keydata = nil
        keydata = M::SshKeyPair.generate_key_pair(s.uuid)
        private_key = keydata[:private_key]
        s.public_key = keydata[:public_key]
        s.finger_print = keydata[:finger_print]
      end

      if params[:description]
        s.description = params[:description]
      end

      if params[:service_type]
        validate_service_type(params[:service_type])
        s.service_type = params[:service_type]
      end

      if params[:display_name]
        s.display_name = params[:display_name]
      end
    end

    begin
      ssh.save
    rescue => e
      raise E::DatabaseError, e.message
    end

    unless params['labels'].blank?
      labels_param_each_pair(params['labels']) do |name, value|
        ssh.set_label(name, value)
      end
    end

    respond_with(R::SshKeyPair.new(ssh, private_key).generate)
  end

  delete '/:id' do
    # description "Remove ssh key pair information"
    # params :id required
    ssh = find_by_uuid(:SshKeyPair, params[:id])
    raise E::UnknownSshKeyPair, params[:id] if ssh.nil?

    force = false
    if params[:force] == 'true'
      force = true
    end

    begin
      ssh.force = force
      ssh.destroy
    rescue => e
      raise E::ExistsRegisteredInstance, e.message
    end

    respond_with([ssh.canonical_uuid])
  end

  put '/:id' do
    # description "Update ssh key pair information"
    ssh = find_by_uuid(:SshKeyPair, params[:id])
    ssh.description = params[:description] if params[:description]
    if params[:service_type]
      validate_service_type(params[:service_type])
      ssh.service_type = params[:service_type]
    end
    ssh.display_name = params[:display_name] if params[:display_name]
    ssh.save_changes

    respond_with([ssh.canonical_uuid])
  end
end

