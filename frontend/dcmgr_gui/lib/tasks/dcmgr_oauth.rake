namespace :oauth do
  desc 'Create oauth consumer'
  task :create_consumer,[:login_id] => :environment do |t,args|
    
    user = User.find(:login_id => args[:login_id])
    
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
