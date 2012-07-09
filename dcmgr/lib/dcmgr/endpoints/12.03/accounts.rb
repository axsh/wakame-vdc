# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/account'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/accounts' do
  namespace '/:id' do
    before do
      @account = M::Account[params[:id]] || raise(UnknownUUIDError, params[:id])
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
  end
end
