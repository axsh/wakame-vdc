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
    AccountLog.filter('YEAR(target_date) = ? AND MONTH(target_date) = ?',
                      year, month).all.length.should == 2
  end

  it "should get instance, account, status, type, minute) by month"
end
