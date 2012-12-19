# encoding: utf-8

require 'sinatra/quota_evaluation'

COMMON_DS_FILTER=proc { |ds|
  ds = ds.filter(:account_id=>@account.canonical_uuid) if @account
  ds = ds.filter(:service_type => params[:service_type]) if params[:service_type]
  ds
}

Sinatra::QuotaEvaluation.evaluators do
  M = Dcmgr::Models

  quota_type 'security_group.count' do
    fetch do
      self.instance_exec(M::SecurityGroup.dataset, &COMMON_DS_FILTER).count
    end

    evaluate do |fetch_value|
      quota_value.to_i <= fetch_value
    end
  end
  quota_type 'ssh_key_pair.count' do
    fetch do
      self.instance_exec(M::SshKeyPair.dataset, &COMMON_DS_FILTER).count
    end

    evaluate do |fetch_value|
      quota_value.to_i <= fetch_value
    end
  end
  quota_type 'instance.quota_weight' do
    fetch do
      (self.instance_exec(M::Instance.alives, &COMMON_DS_FILTER).sum(:quota_weight) || 0.0)
    end

    evaluate do |fetch_value, req_value|
      quota_value.to_f < (fetch_value + req_value)
    end
  end
  quota_type 'instance.count' do
    fetch do
      self.instance_exec(M::Instance.alives, &COMMON_DS_FILTER).count
    end

    evaluate do |fetch_value|
      quota_value.to_i <= fetch_value 
    end
  end
  quota_type 'instance.backup_operations_per_hour' do
    fetch do
      ds = self.instance_exec(M::Image.alives, &COMMON_DS_FILTER)
      ds.filter(:created_at=>(Time.now.utc - 60 * 60) .. (Time.now.utc)).count
    end

    evaluate do |fetch_value|
      quota_value.to_i <= fetch_value
    end
  end
  quota_type 'volume.count' do
    fetch do
      self.instance_exec(M::Volume.alives, &COMMON_DS_FILTER).count
    end

    evaluate do |fetch_value|
      quota_value.to_i <= fetch_value
    end
  end
  quota_type 'volume.size_mb' do
    fetch do
      ((self.instance_exec(M::Volume.alives, &COMMON_DS_FILTER).sum(:size) || 0) / (1024 * 1024))
    end

    evaluate do |fetch_value, req_value|
      quota_value.to_i <= (fetch_value + req_value)
    end
  end
  quota_type 'image.count' do
    fetch do
      self.instance_exec(M::Image.alives, &COMMON_DS_FILTER).count
    end

    evaluate do |fetch_value|
      quota_value.to_i <= fetch_value
    end
  end
  quota_type 'backup_object.count' do
    fetch do
      self.instance_exec(M::BackupObject.alives, &COMMON_DS_FILTER).count
    end

    evaluate do |fetch_value|
      quota_value.to_i <= fetch_value
    end
  end
  quota_type 'backup_object.size_mb' do
    fetch do
      ((self.instance_exec(M::BackupObject.alives, &COMMON_DS_FILTER).sum(:size) || 0) / (1024 * 1024)).truncate
    end

    evaluate do |fetch_value, req_value|
      quota_value.to_i <= (fetch_value + req_value)
    end
  end
  quota_type 'load_balancer.count' do
    fetch do
      cond = {}
      cond[:account_id]=@account.canonical_uuid if @account
      # Load Balancer table does not have service_type field
      M::LoadBalancer.alives.filter(cond).count
    end

    evaluate do |fetch_value|
      quota_value.to_i <= fetch_value
    end
  end
  quota_type 'network.count' do
    fetch do
      self.instance_exec(M::Network.dataset, &COMMON_DS_FILTER).count
    end

    evaluate do |fetch_value|
      quota_value.to_i <= fetch_value
    end
  end
end
