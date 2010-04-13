require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "log access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    reset_db
    @log_c = ar_class :Log
    @accountlog_c = ar_class :AccountLog
    @now = Time.now

    Log.create(:action=>'run',
               :target_uuid=>'I-00000001',
               :account=>Account[2],
               :user=>User[1])
    AccountLog.generate(@now.year, @now.month)
  end

  it "should find by month" do
    logs = @log_c.find(:all, :params=>{
                         :account=>Account[1].uuid,
                         :year=>@now.year, :month=>@now.month})
    logs.length.should == 0

    logs = @log_c.find(:all, :params=>{
                         :account=>Account[2].uuid,
                         :year=>@now.year, :month=>@now.month})
    logs.length.should == 1
  end
  
  it "should find account log by month" do
    logs = @accountlog_c.find(:all, :params=>{
                                :account=>Account[1].uuid,
                                :year=>@now.year, :month=>@now.month})
    logs.length.should == 0

    logs = @accountlog_c.find(:all, :params=>{
                                :account=>Account[2].uuid,
                                :year=>@now.year, :month=>@now.month})
    logs.length.should == 1
  end
end
