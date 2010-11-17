namespace :db do
  desc 'Initialize database'
  task :init => :environment do
    Schema::create!
  end
  
  task :sample_data => :environment do
    DB = Schema.current_connect
    encrypted_password = User.encrypt_password('demo')
    sql = 'insert into users(uuid,login_id,password,primary_account_id,created_at,updated_at) values(?,?,?,?,now(),now())'
    DB['users'].with_sql(sql,'00000000','demo',encrypted_password,'00000000').first

    sql = 'insert into accounts(uuid,name,enable,created_at,updated_at) values(?,?,?,now(),now())'
    DB['accounts'].with_sql(sql,'00000000','demo',1).first

    sql = 'insert into users_accounts(user_id,account_id) values(?,?)'
    DB['users_accounts'].with_sql(sql,1,1).first
  end
  
  task :add_information => :environment do
    DB = Schema.current_connect
    publish_date = '2010-11-19 9:00:00'
    sql = 'insert into information(title,description,created_at,updated_at) values(?,?,?,?)'
    title = "新機能の提供を開始しました。"
    description = "・GUIの提供・KVM対応\n・EBSとしてZFS対応\n・セキュリティグループ対応'\n"
    DB['information'].with_sql(sql,title,description,publish_date,publish_date).first
  end
end

namespace :admin do
  desc 'Create user'
  task :create_user,[:login_id,:password] => :environment do |t,args|
    password = encrypted_password = User.encrypt_password(args[:password])
    User.create(:login_id => args[:login_id],:password => password)
  end
end