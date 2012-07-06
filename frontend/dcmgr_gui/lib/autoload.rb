
$LOAD_PATH.unshift File.expand_path('../../app', __FILE__)

autoload :BaseNew, 'models/base_new'
autoload :Account, 'models/account'
autoload :User, 'models/user'
autoload :Information, 'models/information'
autoload :OauthConsumer, 'models/oauth_consumer'
autoload :AccountQuota, 'models/account_quota'
