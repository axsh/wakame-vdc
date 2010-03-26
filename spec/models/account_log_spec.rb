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
    Log.destroy

    #    | prev month | current month |
    # A) |                 <--->
    # B) |                 <----------
    # C) |   <------------------------
    # D) |   <------------->
    # E) |   <----------> <--> <--> <-

    # A)
    Log.create(:action=>'run',
               :target_uuid=>'I-00000001',
               :account=>Account[1],
               :user=>User[1]).update(:created_at=>Time.gm(2010, 1, 1))
    Log.create(:action=>'terminate',
               :target_uuid=>'I-00000001',
               :account=>Account[1],
               :user=>User[1]).update(:created_at=>Time.gm(2010, 1, 10))

    # B)
    Log.create(:action=>'run',
               :target_uuid=>'I-00000002',
               :account=>Account[1],
               :user=>User[1]).update(:created_at=>Time.gm(2010, 1, 3))


    # C)
    Log.create(:action=>'run',
               :target_uuid=>'I-00000003',
               :account=>Account[2],
               :user=>User[1]).update(:created_at=>Time.gm(2009, 12, 25))
    Log.create(:action=>'run',
               :target_uuid=>'I-00000004',
               :account=>Account[2],
               :user=>User[1]).update(:created_at=>Time.gm(2009, 12, 25))
    Log.create(:action=>'terminate',
               :target_uuid=>'I-00000004',
               :account=>Account[2],
               :user=>User[1]).update(:created_at=>Time.gm(2009, 12, 31))

    # D)
    Log.create(:action=>'run',
               :target_uuid=>'I-00000005',
               :account=>Account[2],
               :user=>User[1]).update(:created_at=>Time.gm(2009, 1, 2))
    Log.create(:action=>'terminate',
               :target_uuid=>'I-00000005',
               :account=>Account[2],
               :user=>User[1]).update(:created_at=>Time.gm(2010, 1, 2))

    # E)
    Log.create(:action=>'run',
               :target_uuid=>'I-00000006',
               :account=>Account[2],
               :user=>User[1]).update(:created_at=>Time.gm(2009, 1, 2))
    Log.create(:action=>'terminate',
               :target_uuid=>'I-00000006',
               :account=>Account[2],
               :user=>User[1]).update(:created_at=>Time.gm(2010, 1, 2))
    Log.create(:action=>'run',
               :target_uuid=>'I-00000006',
               :account=>Account[2],
               :user=>User[1]).update(:created_at=>Time.gm(2009, 1, 5))
    Log.create(:action=>'terminate',
               :target_uuid=>'I-00000006',
               :account=>Account[2],
               :user=>User[1]).update(:created_at=>Time.gm(2010, 1, 7))
    Log.create(:action=>'run',
               :target_uuid=>'I-00000006',
               :account=>Account[2],
               :user=>User[1]).update(:created_at=>Time.gm(2009, 1, 20))
    Log.create(:action=>'terminate',
               :target_uuid=>'I-00000006',
               :account=>Account[2],
               :user=>User[1]).update(:created_at=>Time.gm(2010, 1, 21))
    Log.create(:action=>'run',
               :target_uuid=>'I-00000006',
               :account=>Account[2],
               :user=>User[1]).update(:created_at=>Time.gm(2009, 1, 31))

    p preview_month_instances = AccountLog.preview_month_instances(2010, 1)
    
    preview_month_instances.length.should == 3
    target_uuid = preview_month_instances.keys[0]
    preview_month_instances[target_uuid].account_id.should == Account[2].id
    preview_month_instances[target_uuid].target_uuid.should == 'I-00000003'
    
    AccountLog.generate(2010, 1)
    logs = AccountLog.filter('YEAR(target_date) = ? AND MONTH(target_date) = ?',
                             2010, 1).all

    logs[0].target_uuid.should == 'I-00000001'
    logs[0].account.should == Account[1]
    logs[0].usage_value.should == 60 * 24 * 9

    logs[1].target_uuid.should == 'I-00000002'
    logs[1].account.should == Account[1]
    logs[1].usage_value.should == 60 * 24 * 29

    logs[2].target_uuid.should == 'I-00000003'
    logs[2].account.should == Account[2]
    logs[2].usage_value.should == 60 * 24 * 31

    logs[3].target_uuid.should == 'I-00000005'
    logs[3].account.should == Account[2]
    logs[3].usage_value.should == 60 * 24 * 1

    logs[4].target_uuid.should == 'I-00000006'
    logs[4].account.should == Account[2]
    logs[4].usage_value.should == 60 * 24 * 1

    logs[5].target_uuid.should == 'I-00000006'
    logs[5].account.should == Account[2]
    logs[45].usage_value.should == 60 * 24 * 5
  end
end
