require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "log access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    reset_db
    @log_c = ar_class :Log
    @accountlog_c = ar_class :AccountLog
  end

  it "should find by month" do
    date = Time.now
    logs = @log_c.find(:all, :params=>{
                         :account=>Account[1].uuid,
                         :year=>date.year, :month=>date.month})
    logs.should be_true
  end
  
  it "should find account log by month" do
    date = Time.now
    logs = @accountlog_c.find(:all, :params=>{
                         :account=>Account[1].uuid,
                         :year=>date.year, :month=>date.month})
    logs.should be_true
    pending("get response account, instance, status, server type, time(minute)")
  end
end
