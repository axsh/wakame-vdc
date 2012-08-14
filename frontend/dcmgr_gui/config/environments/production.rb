DcmgrGui::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = true 

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = false

  if config.respond_to?(:action_controller)
    config.action_view.debug_rjs             = false
    config.action_controller.perform_caching = true
    # Only use best-standards-support built into browsers
    config.action_dispatch.best_standards_support = :builtin
    
    #config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'
  end

  # Don't care if the mailer can't send
  #config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Config authentication for WebAPI
  # Setting proxy server
  config.proxy_host = "127.0.0.1"
  config.proxy_port = 8080
  config.proxy_scheme = "http"
  config.proxy_dcmgr_host = "127.0.0.1"
  config.proxy_dcmgr_port = 9001
  config.proxy_root_user = 'root'
  config.proxy_nginx = '/opt/nginx/sbin/nginx'

  # Setting Load balancer spec
  config.load_balancer_spec_id = 'lb.small'

  # Setting authentication server
  config.auth_host = "127.0.0.1"
  config.auth_port = 3000
  config.auth_root_user = 'root'

  if config.respond_to?(:i18n)
    config.i18n.load_path += Dir[Rails.root.join('locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = true
  end
end
