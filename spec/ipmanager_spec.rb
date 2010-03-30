require File.dirname(__FILE__) + '/spec_helper'

describe Dcmgr::IPManager do
  it "should assign ip" do
    instance = Instance.create(:status=>Instance::STATUS_TYPE_RUNNING,
                               :account=>Account[1],
                               :user=>User[1],
                               :image_storage=>ImageStorage[1],
                               :need_cpus=>1,
                               :need_cpu_mhz=>0.5,
                               :need_memory=>500,
                               :hv_agent=>HvAgent[1])
    # called Dcmgr::IPManager.assign_ips(instance)

    ips = instance.ip_dataset.find_by_group_name('newbr0').all
    ips.length.should == 1

    ip = ips.first
    ip.ip_group.name.should == 'newbr0'
    ip.ip.should match(/^192\.168\.1\.\d+$/)
    ip.mac.should match(/^00:00:\d\d$/)
  end
end
