
$LOAD_PATH.unshift File.expand_path('../../app', __FILE__)

autoload :BaseNew, 'models/base_new'
autoload :Account, 'models/account'
autoload :User, 'models/user'
autoload :Tag, 'models/tag'
autoload :TagMapping, 'models/tag_mapping'
autoload :Information, 'models/information'
autoload :OauthToken, 'models/oauth_token'
autoload :AccountQuota, 'models/account_quota'
