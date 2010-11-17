namespace :db do
  desc 'Initialize database'
  task :init => :environment do
    Schema::create!
  end
  
  task :sample_data => :environment do
    User.create(:uuid => '00000000',
                :login_id => 'demo',
                :password => User.encrypt_password('demo'),
                :primary_account_id => '00000000'
                )

    Account.create(:uuid => '00000000',
                   :name => 'demo',
                   :enable => 1
                   )

    sql = 'insert into users_accounts(user_id,account_id) values(?,?)'
    DB = Schema.current_connect
    DB['users_accounts'].with_sql(sql,1,1).first

    publish_date = '2010-11-19 9:00:00'
    title = "新機能の提供を開始しました。"
    description = "・GUIの提供・KVM対応\n・EBSとしてZFS対応\n・セキュリティグループ対応'\n"
    
    Information.create(:title => title,
                       :description => description,
                       :created_at => publish_date
                       )
    
  end
end

namespace :admin do
  desc 'Create user'
  task :create_user,[:login_id,:password] => :environment do |t,args|
    password = encrypted_password = User.encrypt_password(args[:password])
    User.create(:login_id => args[:login_id],:password => password)
  end
end