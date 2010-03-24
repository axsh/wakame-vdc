require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "account log" do
  include ActiveResourceHelperMethods

  it "should genelate logs" do
    year = 2010; month = 1

    Log.create(:action=>'run',
               :target_uuid=>'I-00000001',
               :account=>Account[1],
               :user=>User[1]).update(:created_at=>Time.gm(year, month, 1))

    Log.create(:action=>'terminate',
               :target_uuid=>'I-00000001',
               :account=>Account[1],
               :user=>User[1]).update(:created_at=>Time.gm(year, month, 10))

    Log.create(:action=>'run',
               :target_uuid=>'I-00000002',
               :account=>Account[1],
               :user=>User[1]).update(:created_at=>Time.gm(year, month, 3))

    AccountLog.generate(year, month)
    logs = AccountLog.filter('YEAR(target_date) = ? AND MONTH(target_date) = ?',
                             year, month).all
    logs.length.should == 2
  end

  it "should get instance, account, minute) by month" do
    year = 2010; month = 1

    Log.destroy

    Log.create(:action=>'run',
               :target_uuid=>'I-00000001',
               :account=>Account[1],
               :user=>User[1]).update(:created_at=>Time.gm(year, month, 1))

    Log.create(:action=>'terminate',
               :target_uuid=>'I-00000001',
               :account=>Account[1],
               :user=>User[1]).update(:created_at=>Time.gm(year, month, 10))

    Log.create(:action=>'run',
               :target_uuid=>'I-00000002',
               :account=>Account[1],
               :user=>User[1]).update(:created_at=>Time.gm(year, month, 3))

    AccountLog.generate(year, month)
    logs = AccountLog.filter('YEAR(target_date) = ? AND MONTH(target_date) = ?',
                             year, month).all

    logs[0].target_uuid.should == 'I-00000001'
    logs[0].account.should == Account[1]
    logs[0].usage_value.should == 12960

    logs[1].target_uuid.should == 'I-00000002'
    logs[1].account.should == Account[1]
    logs[1].usage_value.should == 41760
  end
end
