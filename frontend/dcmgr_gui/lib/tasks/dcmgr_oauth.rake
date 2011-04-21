namespace :oauth do
  desc 'Create oauth consumer'
  task :create_consumer,[:vdc_account_uuid] => :environment do |t,args|
    
    split_uuid = args[:vdc_account_uuid].split('-')
    
    if args[:vdc_account_uuid].nil? or split_uuid[0] != 'a'
      puts 'Please set the wakame-vdc account uuid.'
      exit(0)
    end

    account_uuid = split_uuid[1]
    account = Account.find(:uuid => account_uuid)
    
    if account.nil?
      puts "Account not found."
      exit(0)
    end
    
    oauth_consumer = OauthConsumer.find(:account_id => account.id)
    
    if oauth_consumer.nil?
      oauth_token = OauthToken.new
      oauth_token.generate_keys
      oauth_consumer = OauthConsumer.create(
                               :key => oauth_token.token,
                               :secret => oauth_token.secret,
                               :account_id => account.id
                              )
    end
    puts "consumer_key=#{oauth_consumer.key}"
    puts "secret_key=#{oauth_consumer.secret}"
  end
  
  desc 'Create table'
  task :create_table => :environment do |t,args|
    OauthConsumer.create_table!
  end
end
