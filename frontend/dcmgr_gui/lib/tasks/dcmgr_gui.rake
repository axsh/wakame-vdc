namespace :db do
  desc 'Initialize database'
  task :init => [ :environment ] do
    Sequel.extension :migration
    Sequel::Migrator.apply(Sequel::DATABASES.first, File.expand_path('db/migrations', Rails.root), 9999)
  end

  desc 'Drop database'
  task :drop => [ :environment ] do
    Sequel.extension :migration
    Sequel::Migrator.apply(Sequel::DATABASES.first, File.expand_path('db/migrations', Rails.root), 0)
  end
end

namespace :admin do
  desc 'Import RSS to information table'
  task :create_information,[:url] => :environment do |t, args|
    require 'net/http'
    require 'uri'
    require 'rexml/document'

    if args[:url].nil? || args[:url] == ''
      STDERR.puts 'Please set the url.'
      exit(1)
    end

    begin
      rss_uri = URI.parse(args[:url])
    rescue => e
      STDERR.puts "Invalid URL input: #{args[:url]}"
      exit 1
    end

    Information.truncate

    doc = REXML::Document.new(Net::HTTP.get(rss_uri))
    REXML::XPath.each(doc, '//item') do |i|
      Information.create(:title => REXML::XPath.first(i, 'title').text,
                         :description => REXML::XPath.first(i, 'description').text,
                         :link => REXML::XPath.first(i, 'link').text,
                         :created_at => DateTime.parse(REXML::XPath.first(i, 'pubDate').text))
    end
  end

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
            
            if ['button', 'parts', 'pagenate', 'date', 'error_box'].include? key
              data[key].keys.each do |i18n_key|
                i18n_value = data[key][i18n_key]
                if i18n_value
                  i18n_table.push({:key => "#{i18n_key}_#{key}",
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
