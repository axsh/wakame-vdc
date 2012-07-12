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

      common_filter = proc { |model|
        ds = if model.respond_to?(:alives)
               model.alives
             else
               model.dataset
             end.filter(:account_id=>params[:id])
        
        if params[:service_type]
          validate_service_type(params[:service_type])
          ds = ds.filter(:service_type=>params[:service_type])
        end

        ds
      }

      res = {}
      ds = common_filter.call(M::Instance)
      res['instance.count'] =ds.count
      res['instance.quota_weight']=ds.sum(:quota_weight).to_f

      ds = common_filter.call(M::Volume)
      res['volume.count'] = ds.count
      Dcmgr::Helpers::ByteUnit.instance_eval { |m|
        res['volume.size_mb'] = m.convert_byte(ds.sum(:size), m::MB)
      }

      ds = common_filter.call(M::SshKeyPair)
      res['ssh_key_pair.count'] = ds.count
      ds = common_filter.call(M::SecurityGroup)
      res['security_group.count'] = ds.count

      ds = common_filter.call(M::Network)
      res['network.count'] = ds.count

      ds = common_filter.call(M::Image)
      res['image.count'] = ds.count

      ds = common_filter.call(M::BackupObject)
      res['backup_object.count'] = ds.count
      Dcmgr::Helpers::ByteUnit.instance_eval { |m|
        res['backup_object.size_mb'] = m.convert_byte(ds.sum(:size), m::MB)
      }
      
      respond_with(R::AccountUsage.new(@account, res).generate)
    end
    
    # Delete all security groups with the Account.
    delete '/security_groups' do
      #M::SecurityGroup.alives.filter(:account_id=>@account.canonical_uuid).each { |i|
      M::SecurityGroup.filter(:account_id=>@account.canonical_uuid).each { |i|
        request_forward.delete("/security_groups/#{i.canonical_uuid}")
      }
      respond_with({})
    end

    # Delete all sshe keys with the Account.
    delete '/ssh_key_pairs' do
      #M::SshKeyPair.alives.filter(:account_id=>@account.canonical_uuid).each { |i|
      M::SshKeyPair.filter(:account_id=>@account.canonical_uuid).each { |i|
        request_forward.delete("/ssh_key_pairs/#{i.canonical_uuid}")
      }
      respond_with({})
    end
  end
end
