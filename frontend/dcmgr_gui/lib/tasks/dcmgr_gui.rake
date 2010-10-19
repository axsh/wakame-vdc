namespace :db do
  desc 'Initialize database'
  task :init => :environment do
    Frontend::Schema::create!
  end
  
  task :sample_data => :environment do
    DB = Frontend::Schema.current_connect
    sql = 'insert into users(uuid,login_id,password,primary_account_id) values(?,?,?,?)'
    DB['users'].with_sql(sql,'00000000','test','password','00000000').first

    sql = 'insert into accounts(uuid,name,enable) values(?,?,?)'
    DB['accounts'].with_sql(sql,'00000000','test_account1',1).first

    sql = 'insert into accounts(uuid,name,enable) values(?,?,?)'
    DB['accounts'].with_sql(sql,'00000001','test_account2',1).first

    sql = 'insert into users_accounts(user_id,account_id) values(?,?)'
    DB['users_accounts'].with_sql(sql,1,1).first
    DB['users_accounts'].with_sql(sql,1,2).first    
  end
end
