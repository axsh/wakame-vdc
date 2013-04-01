# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/ssh_key_pair'
require 'sshkey'
Dcmgr::Endpoints::V1203::CoreAPI.namespace '/ssh_key_pairs' do
  register V1203::Helpers::ResourceLabel
  enable_resource_label(M::SshKeyPair)

  get do
    ds = M::SshKeyPair.dataset
    if params[:account_id]
      ds = ds.filter(:account_id=>params[:account_id])
    end

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

  get '/:id' do
    # description "Retrieve details about ssh key pair"
    # params :id required
    # params :format optional [openssh,putty]
    ssh = find_by_uuid(:SshKeyPair, params[:id])
    raise UnknownSshKeyPair, parmas[:id] if ssh.nil?

    respond_with(R::SshKeyPair.new(ssh).generate)
  end

  quota 'ssh_key_pair.count'
  post do
    # description "Create ssh key pair information"
    # params :display_name optional
    private_key = nil
    ssh = M::SshKeyPair.entry_new(@account) do |s|

      unless params[:public_key].empty?
        public_key = URI.decode(params[:public_key])
        error = 0
        error += 1 unless SSHKey.valid_ssh_public_key?(public_key)
        result = `/usr/bin/ssh-keygen -lf /dev/stdin <<< '#{public_key}'`
        error += 1 unless $? == 0
        raise InvalidSshPublicKey, params[:public_key] if  error > 0

        s.public_key = public_key
        s.finger_print = result.split(' ')[1]
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

