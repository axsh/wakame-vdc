# encoding: utf-8

require 'sinatra/quota_evaluation'

Sinatra::QuotaEvaluation.evaluators do
  quota_type 'security_group.count' do
    fetch do
      M::SecurityGroup.filter(:account_id=>@account.canonical_uuid).count
    end

    evaluate do |fetch_value|
      quota_value.to_i <= fetch_value
    end
  end
  quota_type 'ssh_key_pair.count' do
    fetch do
      M::SshKeyPair.filter(:account_id=>@account.canonical_uuid).count
    end
    
    evaluate do |fetch_value|
      quota_value.to_i <= fetch_value
    end
  end
  quota_type 'instance.quota_weight' do
    fetch do
      (M::Instance.lives.filter(:account_id=>@account.canonical_uuid).sum(:quota_weight) || 0.0)
    end
    
    evaluate do |fetch_value|
      quota_value.to_f <= fetch_value
    end
  end
  quota_type 'instance.count' do
    fetch do
      M::Instance.lives.filter(:account_id=>@account.canonical_uuid).count
    end
    
    evaluate do |fetch_value|
      quota_value.to_i <= fetch_value
    end
  end
  quota_type 'volume.count' do
    fetch do
      M::Volume.filter(:account_id=>@account.canonical_uuid).count
    end
    
    evaluate do |fetch_value|
      quota_value.to_i <= fetch_value
    end
  end
  quota_type 'volume.size_mb' do
    fetch do
      ((M::Volume.filter(:account_id=>@account.canonical_uuid).sum(:volume_size) || 0) / (1024 * 1024))
    end
    
    evaluate do |fetch_value|
      quota_value.to_i <= fetch_value
    end
  end
  quota_type 'image.count' do
    fetch do
      M::Image.filter(:account_id=>@account.canonical_uuid).count
    end
    
    evaluate do |fetch_value|
      quota_value.to_i <= fetch_value
    end
  end
  quota_type 'backup_object.count' do
    fetch do
      M::BackupObject.filter(:account_id=>@account.canonical_uuid).count
    end

    evaluate do |fetch_value|
      quota_value.to_i <= fetch_value
    end
  end
  quota_type 'backup_object.size_mb' do
    fetch do
      ((M::BackupObject.filter(:account_id=>@account.canonical_uuid).sum(:size) || 0) / (1024 * 1024))
    end

    evaluate do |fetch_value| 
      quota_value.to_i <= fetch_value
    end
  end
  quota_type 'load_balancer.count' do
    fetch do
      M::LoadBalancer.alives.filter(:account_id=>@account.canonical_uuid).count
    end

    evaluate do |fetch_value| 
      quota_value.to_i <= fetch_value
    end
  end
end
