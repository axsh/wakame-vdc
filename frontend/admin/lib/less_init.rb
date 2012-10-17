module LessInitializer
  def self.registered(app)
    # Enables support for Less template reloading for rack.
    # Store Less files by default within 'app/stylesheets/'
    # See http://github.com/kelredd/rack-less for more details.
    require 'rack/less'
    # optional - use as necessary
    Rack::Less.configure do |config|
      config.compress = true
      # config.cache = true
      # other configs ...
    end
    app.use Rack::Less,
      :root      => Padrino.root,
      :source    => 'app/stylesheets',
      :public    => 'public',
      :hosted_at => 'stylesheets'

  end
end
