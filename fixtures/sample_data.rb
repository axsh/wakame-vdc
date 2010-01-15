
account = Account.create(:name=>'__test_account__')
user = User.create(:name=>'__test__', :password=>'passwd')
user.add_account(account)

image_storage_host = ImageStorageHost.create
image_storage = ImageStorage.create(:image_storage_host=>image_storage_host)

physical_host_a = PhysicalHost.create(:cpus=>4, :cpu_mhz=>1.0,
                                      :memory=>2.0,
                                      :hypervisor_type=>'xen')
PhysicalHost[physical_host_a.id].remove_tag(Tag::SYSTEM_TAG_GET_READY_INSTANCE)
physical_host_b = PhysicalHost.create(:cpus=>2, :cpu_mhz=>1.6,
                                      :memory=>1.0,
                                      :hypervisor_type=>'xen')
PhysicalHost[physical_host_b.id].remove_tag(Tag::SYSTEM_TAG_GET_READY_INSTANCE)
physical_host_c = PhysicalHost.create(:cpus=>1, :cpu_mhz=>2.0,
                                      :memory=>4.0,
                                      :hypervisor_type=>'xen')
PhysicalHost[physical_host_c.id].remove_tag(Tag::SYSTEM_TAG_GET_READY_INSTANCE)

hv_controller = HvController.create(:physical_host=>physical_host_a,
                                    :ip=>'192.168.1.10')

hv_agent_a = HvAgent.create(:hv_controller=>hv_controller,
                            :physical_host=>physical_host_a,
                            :ip=>'192.168.1.20')
hv_agent_b = HvAgent.create(:hv_controller=>hv_controller,
                            :physical_host=>physical_host_a,
                            :ip=>'192.168.1.30')
hv_agent_c = HvAgent.create(:hv_controller=>hv_controller,
                            :physical_host=>physical_host_a,
                            :ip=>'192.168.1.40')

instance_a = Instance.create(:status=>0, # offline
                             :account=>account,
                             :user=>user,
                             :image_storage=>image_storage,
                             :need_cpus=>1,
                             :need_cpu_mhz=>1.0,
                             :need_memory=>0.5,
                             :hv_agent=>hv_agent_a,
                             :ip=>'192.168.2.100')

normal_tag_a = Tag.create(:name=>'sample tag a',
                          :account=>account)

instance_crud = Tag.create(:name=>'sample instance crud',
                           :role=>0,
                           :account=>account)

TagMapping.create(:tag=>instance_crud,
                 :target_type=>TagMapping::TYPE_INSTANCE,
                 :target_id=>instance_a.id)
