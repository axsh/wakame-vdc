
account_a = Account.create(:name=>'__test_account__', :contract_at=>Time.now)
account_b = Account.create(:name=>'__test_account2__')

user = User.create(:name=>'__test__', :password=>'passwd')
user.add_account(account_a)

image_storage_host = ImageStorageHost.create
image_storage = ImageStorage.create(:image_storage_host=>image_storage_host)

physical_host_a = PhysicalHost.create(:cpus=>4, :cpu_mhz=>1.0,
                                      :memory=>2000,
                                      :hypervisor_type=>'xen')
PhysicalHost[physical_host_a.id].remove_tag(Tag.system_tag(:STANDBY_INSTANCE))
physical_host_b = PhysicalHost.create(:cpus=>2, :cpu_mhz=>1.6,
                                      :memory=>1000,
                                      :hypervisor_type=>'xen')
PhysicalHost[physical_host_b.id].remove_tag(Tag.system_tag(:STANDBY_INSTANCE))
physical_host_c = PhysicalHost.create(:cpus=>1, :cpu_mhz=>2.0,
                                      :memory=>8000,
                                      :hypervisor_type=>'xen')
PhysicalHost[physical_host_c.id].remove_tag(Tag.system_tag(:STANDBY_INSTANCE))

hv_controller = HvController.create(:physical_host=>physical_host_a,
                                    :ip=>'192.168.1.10')

hv_agent_a = HvAgent.create(:hv_controller=>hv_controller,
                            :physical_host=>physical_host_a,
                            :ip=>'192.168.1.20')
hv_agent_b = HvAgent.create(:hv_controller=>hv_controller,
                            :physical_host=>physical_host_b,
                            :ip=>'192.168.1.30')
hv_agent_c = HvAgent.create(:hv_controller=>hv_controller,
                            :physical_host=>physical_host_c,
                            :ip=>'192.168.1.40')

instance_a = Instance.create(:status=>0, # offline
                             :account=>account_a,
                             :user=>user,
                             :image_storage=>image_storage,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.5,
                             :need_memory=>500,
                             :hv_agent=>hv_agent_a,
                             :ip=>'192.168.2.100')

normal_tag_a = Tag.create(:name=>'sample tag a',
                          :account=>account_a)

TagMapping.create(:tag=>normal_tag_a,
                  :target_type=>TagMapping::TYPE_INSTANCE,
                  :target_id=>instance_a.id)

[Dcmgr::RoleExecutor::RunInstance,
 Dcmgr::RoleExecutor::ShutdownInstance].each{|role|
  role_tag = Tag.create(:name=>role.name,
                        :role=>role.id,
                        :account=>account_a,
                        :owner=>user)
  TagMapping.create(:tag=>normal_tag_a,
                    :target_type=>TagMapping::TYPE_TAG,
                    :target_id=>role_tag.id)
}

Tag.create(:name=>Account.tags[0].name,
           :role=>Dcmgr::RoleExecutor::CreateAccount.id,
           :account=>account_a,
           :owner=>user)

Tag.create(:name=>Account.tags[0].name,
           :role=>Dcmgr::RoleExecutor::DestroyAccount.id,
           :account=>account_a,
           :owner=>user)

Tag.create(:name=>ImageStorage.tags[0].name,
           :role=>Dcmgr::RoleExecutor::CreateImageStorage.id,
           :account=>account_a,
           :owner=>user)

Tag.create(:name=>ImageStorage.tags[0].name,
           :role=>Dcmgr::RoleExecutor::GetImageStorageClass.id,
           :account=>account_a,
           :owner=>user)

Tag.create(:name=>ImageStorage.tags[0].name,
           :role=>Dcmgr::RoleExecutor::DestroyImageStorage.id,
           :account=>account_a,
           :owner=>user)

Tag.create(:name=>ImageStorageHost.tags[0].name,
           :role=>Dcmgr::RoleExecutor::CreateImageStorageHost.id,
           :account=>account_a,
           :owner=>user)

Tag.create(:name=>ImageStorageHost.tags[0].name,
           :role=>Dcmgr::RoleExecutor::DestroyImageStorageHost.id,
           :account=>account_a,
           :owner=>user)

Tag.create(:name=>PhysicalHost.tags[0].name,
           :role=>Dcmgr::RoleExecutor::CreatePhysicalHost.id,
           :account=>account_a,
           :owner=>user)

Tag.create(:name=>PhysicalHost.tags[0].name,
           :role=>Dcmgr::RoleExecutor::DestroyPhysicalHost.id,
           :account=>account_a,
           :owner=>user)
