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
  
  desc 'Create account'
  task :create_account,[:user_id,:name] => :environment do |t,args|
    result = Account.create(:name => args[:name],
                   :enable => 1
                   )
    DB = Schema.current_connect
    sql = 'insert into users_accounts(user_id,account_id) values(?,?)'
    DB['users_accounts'].with_sql(sql,args[:user_id],result.id).first
  end
  
  desc 'Generate i18n files for javascript'
  task :generate_i18n => :environment do |t, args|
    locals_path = File.join(RAILS_ROOT, 'config', 'locales')
    I18n.load_path.each do |path|
      if path =~ %r{#{locals_path}}
        locale = path.sub(%r{#{locals_path}/}, '').split('.')[0]
        data = YAML.load(File.read(path))[locale]
        i18n_table = []
        if data.is_a? Hash
          data.keys.each do |key|
            if key == 'dialog'
              data[key].keys.each do |i18n_key|
                i18n_value = data[key][i18n_key]['header']
                if i18n_value
                  i18n_table.push({:key => "#{i18n_key}_header",
                                   :value => i18n_value})
                end
              end
            end
            
            if key == 'button'
              data[key].keys.each do |i18n_key|
                i18n_value = data[key][i18n_key]
                if i18n_value
                  i18n_table.push({:key => "#{i18n_key}_button",
                                   :value => i18n_value})
                end
              end
            end
            
          end
        end
        
        output_data = ''
        i18n_table.each do |data|
          output_data += "#{data[:key]} = #{data[:value]}\n"
        end
        output_filename = "Messages_#{locale}.properties"
        output_file = File.join(File.join(RAILS_ROOT, 'public', 'i18n'), output_filename)
        f = File.open(output_file, "w")
        f.write(output_data)
        f.close
        puts("Generated 18n file #{output_file}")
      end
    end
  end
end