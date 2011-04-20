namespace :oauth do
  desc 'Create oauth consumer'
  task :create_consumer,[:uuid] => :environment do |t,args|
    
    if args[:uuid].nil?
      puts 'Please set the uuid.'
      exit(0)
    end

    uuid = args[:uuid].split('-')[1]
    user = User.find(:uuid => uuid)
    
    if user.nil?
      puts "User not found."
      exit(0)
    end
    
    oauth_consumer = OauthConsumer.find(:user_id => user.id)
    
    if oauth_consumer.nil?
      oauth_token = OauthToken.new
      oauth_token.generate_keys
      oauth_consumer = OauthConsumer.create(
                               :key => oauth_token.token,
                               :secret => oauth_token.secret,
                               :user_id => user.id
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
