# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/account'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/accounts' do
  namespace '/:id' do
    helpers do
      # namespace local modification for Sinatra::InternalRequest#request_forward.
      # It forces to add X-VDC-Account-UUID header with params[:id] of
      # Account ID.
      def request_forward(&blk)
        myself = self
        super() do |m|
          m.header(HTTP_X_VDC_ACCOUNT_UUID, @account.canonical_uuid)
          m.block_eval(&blk) if blk
        end
      end
    end
    
    before do
      @account = M::Account[params[:id]] || raise(E::UnknownUUIDResource, params[:id])
    end

    get do
      respond_with(R::Account.new(@account).generate)
    end
    
    # resource usage summary (active/available only) for the account
    get '/usage' do

      res = {}
      Sinatra::QuotaEvaluation.quota_defs.each do |key, tuple|
        res[key] = self.instance_exec(&tuple[0])
      end
      respond_with(R::AccountUsage.new(@account, res).generate)
    end

    # Turn power off all instances with the Account.
    put '/instances/poweroff' do
      uuids = M::Instance.alives.filter(:account_id=>@account.canonical_uuid, :state=>'running').all.map { |i|
        r = request_forward.put("/instances/#{i.canonical_uuid}/poweroff")
        i.canonical_uuid
      }
      respond_with(uuids)
    end
    
    # Turn power on all instances with the Account.
    put '/instances/poweron' do
      uuids = M::Instance.alives.filter(:account_id=>@account.canonical_uuid, :state=>'halted').all.map { |i|
        request_forward.put("/instances/#{i.canonical_uuid}/poweron")
        i.canonical_uuid
      }
      respond_with(uuids)
    end

    # Terminate all instances with the Account.
    delete '/instances' do
      uuids = M::Instance.alives.filter(:account_id=>@account.canonical_uuid, :state=>['running', 'halted']).all.map { |i|
        request_forward.delete("/instances/#{i.canonical_uuid}")
        i.canonical_uuids
      }
      respond_with(uuids)
    end

    # Turn power off all load balancers with the Account.
    put '/load_balancers/poweroff' do
      uuids = M::LoadBalancer.alives.filter(:account_id=>@account.canonical_uuid).by_state('running').all.map { |i|
        request_forward.put("/load_balancers/#{i.canonical_uuid}/poweroff")
        i.canonical_uuids
      }
      respond_with(uuids)
    end
    
    # Turn power on all the load balancers with the Account.
    put '/load_balancers/poweron' do
      uuids = M::LoadBalancer.alives.filter(:account_id=>@account.canonical_uuid).by_state('halted').all.map { |i|
        request_forward.put("/load_balancers/#{i.canonical_uuid}/poweron")
        i.canonical_uuids
      }
      respond_with(uuids)
    end

    # Terminate all load balancers with the Account.
    delete '/load_balancers' do
      uuids = M::LoadBalancer.alives.filter(:account_id=>@account.canonical_uuid).all.map { |i|
        request_forward.delete("/load_balancers/#{i.canonical_uuid}")
        i.canonical_uuids
      }
      respond_with(uuids)
    end

    # Delete all backup objects with the Account.
    delete '/backup_objects' do
      uuids = M::BackupObject.alives.filter(:account_id=>@account.canonical_uuid, :state=>'halted').all.map { |i|
        request_forward.delete("/backup_objects/#{i.canonical_uuid}")
        i.canonical_uuids
      }
      respond_with(uuids)
    end

    # Delete all volumes with the Account.
    delete '/volumes' do
      uuids = M::Volume.alives.filter(:account_id=>@account.canonical_uuid, :state=>'available').all.map { |i|
        request_forward.delete("/volumes/#{i.canonical_uuid}")
        i.canonical_uuids
      }
      respond_with(uuids)
    end
    
    # Delete all security groups with the Account.
    delete '/security_groups' do
      #M::SecurityGroup.alives.filter(:account_id=>@account.canonical_uuid).all.map { |i|
      uuids = M::SecurityGroup.filter(:account_id=>@account.canonical_uuid).all.map { |i|
        request_forward.delete("/security_groups/#{i.canonical_uuid}")
        i.canonical_uuids
      }
      respond_with(uuids)
    end

    # Delete all sshe keys with the Account.
    delete '/ssh_key_pairs' do
      #M::SshKeyPair.alives.filter(:account_id=>@account.canonical_uuid).all.map { |i|
      uuids = M::SshKeyPair.filter(:account_id=>@account.canonical_uuid).all.map { |i|
        request_forward.delete("/ssh_key_pairs/#{i.canonical_uuid}")
        i.canonical_uuids
      }
      respond_with(uuids)
    end
    
    # Logically delete account. Associating resources will be
    # destroyed later by separate batch job.
    delete do
      @account.destroy
      respond_with([@account.canonical_uuid])
    end
    
  end
end
