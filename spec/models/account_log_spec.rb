require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "account log" do
  include ActiveResourceHelperMethods

  it "should genelate logs" do
    year = 2010; month = 1
    10.times{
      l = Log.create(:action=>'run',
                     :target_uuid=>Instance[1].uuid,
                     :account=>Account[1],
                     :user=>User[1])
      l.update(:created_at=>Time.gm(year, month))
    }
    AccountLog.generate(year, month)
    AccountLog.filter('YEAR(target_date) = ? AND MONTH(target_date) = ?',
                      year, month).all.length.should == 10
  end

  it "should get instance, account, status, type, minute) by month"
end
