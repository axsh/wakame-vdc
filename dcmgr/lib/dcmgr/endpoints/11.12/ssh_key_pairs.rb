# -*- coding: utf-8 -*-

Dcmgr::Endpoints::V1112::CoreAPI.namespace '/ssh_key_pairs' do
  # description "List ssh key pairs in account"
  get do
    # params start, fixnum, optional
    # params limit, fixnum, optional
    res = select_index(:SshKeyPair, {:start => params[:start],
                         :limit => params[:limit]})
    response_to(res)
  end

  get '/:id' do
    # description "Retrieve details about ssh key pair"
    # params :id required
    # params :format optional [openssh,putty]
    ssh = find_by_uuid(:SshKeyPair, params[:id])

    response_to(ssh.to_api_document)
  end

  post do
    # description "Create ssh key pair information"
    # params :download_once optional set true if you do not want
    #        to save private key info on database.
    M::SshKeyPair.lock!
    keydata = nil

    ssh = M::SshKeyPair.entry_new(@account) do |s|
      keydata = M::SshKeyPair.generate_key_pair(s.uuid)
      s.public_key = keydata[:public_key]
      s.finger_print = keydata[:finger_print]

      if params[:download_once] != 'true'
        s.private_key = keydata[:private_key]
      end

      if params[:description]
        s.description = params[:description]
      end
    end

    begin
      ssh.save
    rescue => e
      raise E::DatabaseError, e.message
    end

    # include private_key data in response even if
    # it's not going to be stored on DB.
    response_to(ssh.to_api_document.merge(:private_key=>keydata[:private_key]))
  end

  delete '/:id' do
    # description "Remove ssh key pair information"
    # params :id required
    M::SshKeyPair.lock!
    ssh = find_by_uuid(:SshKeyPair, params[:id])
    if examine_owner(ssh)
      ssh.destroy
    else
      raise E::OperationNotPermitted
    end

    response_to([ssh.canonical_uuid])
  end

  put '/:id' do
    # description "Update ssh key pair information"
    M::SshKeyPair.lock!
    ssh = find_by_uuid(:SshKeyPair, params[:id])
    if examine_owner(ssh)
      ssh.description = params[:description]
      ssh.save_changes
    else
      raise E::OperationNotPermitted
    end

    response_to([ssh.canonical_uuid])
  end
end
