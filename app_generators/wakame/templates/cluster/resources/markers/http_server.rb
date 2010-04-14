module HttpServer
  def self.included(klass)
    klass.class_eval {
      property :listen_port
      property :listen_port_https
    }
  end
end

