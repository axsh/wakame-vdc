require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# describe class:
#   class Instance < ActiveResource::Base
#     self.site = 'http://localhost:port/'
#     self.format = :json
#   end
#
# status:
#   STATUS_TYPE_OFFLINE = 0
#   STATUS_TYPE_RUNNING = 1
#   STATUS_TYPE_ONLINE = 2
#   STATUS_TYPE_TERMINATING = 3
describe "instance access by active resouce(private mode)" do
  include ActiveResourceHelperMethods
  
  before(:all) do
    runserver(:private)
    sleep 1.0
    @c = ar_class_with_basicauth :Instance, :private=>true
  end
  
  it "should change instance status" do
    real_instance = Instance[1]
    real_instance.status = Instance::STATUS_TYPE_RUNNING
    real_instance.status_updated_at = status_updated_at = Time.now - 3600
    real_instance.save
    
    instance = @c.find(Instance[1].uuid)
    instance.status = Instance::STATUS_TYPE_ONLINE
    instance.save
    
    real_instance.reload
    real_instance.status.should == Instance::STATUS_TYPE_ONLINE
    real_instance.status_updated_at.should_not == status_updated_at
    real_instance.status_updated_at.should be_close(Time.now, 2)
  end
end
