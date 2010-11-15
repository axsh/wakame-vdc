namespace :db do
  desc 'Initialize database'
  task :init => :environment do
    Frontend::Schema::create!
  end
  
  task :sample_data => :environment do
    DB = Frontend::Schema.current_connect
    encrypted_password = Frontend::Models::User.encrypt_password('demo')
    sql = 'insert into users(uuid,login_id,password,primary_account_id,created_at,updated_at) values(?,?,?,?,now(),now())'
    DB['users'].with_sql(sql,'00000000','demo',encrypted_password,'00000000').first

    sql = 'insert into accounts(uuid,name,enable,created_at,updated_at) values(?,?,?,now(),now())'
    DB['accounts'].with_sql(sql,'00000000','demo',1).first

    sql = 'insert into users_accounts(user_id,account_id) values(?,?)'
    DB['users_accounts'].with_sql(sql,1,1).first
  end
end