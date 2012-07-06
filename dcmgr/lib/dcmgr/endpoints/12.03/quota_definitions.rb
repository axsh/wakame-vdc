# encoding: utf-8

require 'sinatra/quota_evaluation'

Sinatra::QuotaEvaluation.evaluators do
  quota_key 'security_group.count' do
    quota_value.to_i < M::SecurityGroup.filter(:account_id=>@account.canonical_uuid).count
  end
  quota_key 'ssh_key_pair.count' do
    quota_value.to_i < M::SshKeyPair.filter(:account_id=>@account.canonical_uuid).count
  end
  quota_key 'instance.quota_weight' do
    quota_value.to_f < M::Instance.lives.filter(:account_id=>@account.canonical_uuid).sum(:quota_weight)
  end
  quota_key 'instance.count' do
    quota_value.to_i < M::Instance.lives.filter(:account_id=>@account.canonical_uuid).count
  end
  quota_key 'volume.count' do
    quota_value.to_i < M::Volume.filter(:account_id=>@account.canonical_uuid).count
  end
  quota_key 'volume.size' do
    quota_value.to_i < M::Volume.filter(:account_id=>@account.canonical_uuid).sum(:volume_size)
  end
  quota_key 'image.count' do
    quota_value.to_i < M::Image.filter(:account_id=>@account.canonical_uuid).count
  end
  quota_key 'backup_object.count' do
    quota_value.to_i < M::BackupObject.filter(:account_id=>@account.canonical_uuid).count
  end
  quota_key 'backup_object.size' do
    quota_value.to_i < M::BackupObject.filter(:account_id=>@account.canonical_uuid).sum(:size)
  end
end
