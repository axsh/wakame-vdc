

require 'ostruct'

module Wakame
  # System wide configuration parameters
  class Configuration < OpenStruct

    PARAMS = {
      #:config_template_root => nil,
      #:config_tmp_root => nil,
      :status_db_dsn => nil,
      :config_root => nil,
      :cluster_class => 'WebCluster',
      :load_paths => [],
      :ssh_private_key => nil,
      :http_command_server_uri => 'http://localhost:3000',
      :amqp_server_uri => nil,
      :unused_vm_live_period => 60 * 10,
      :eventmachine_use_epoll => true
    }

    def initialize(env=WAKAME_ENV)
      super(PARAMS)
      if root_path.nil?
        root_path = Object.const_defined?(:WAKAME_ROOT) ? WAKAME_ROOT : '../'
      end

      @root_path = root_path

      self.class.const_get(env).new.process(self)
    end

    def environment
      ::WAKAME_ENV.to_sym
    end
    alias :vm_environment :environment

    def environment_path(key=environment)
      File.expand_path("config/environments/#{Util.snake_case(key.to_s)}.rb", root_path)
    end
    
    def root_path
      ::WAKAME_ROOT
    end

    def tmp_path
      File.join(root_path, 'tmp')
    end

    def ssh_known_hosts
      File.join(self.config_root, "ssh", "known_hosts")
    end

    def config_tmp_root
      File.join(self.config_root, "tmp")
    end

    def framework_root_path
      defined?(::WAKAME_FRAMEWORK_ROOT) ? ::WAKAME_FRAMEWORK_ROOT : "#{root_path}/vendor/wakame"
    end

    def framework_paths
      paths = %w(lib)

      paths.map{|dir| File.join(framework_root_path, dir) }.select{|path| File.directory?(path) }
    end

    def project_paths
      %w(lib).map{|dir| File.join(root_path, dir) }.select{|path| File.directory?(path)}
    end

    def cluster_config_path
      File.expand_path('config/cluster.rb', root_path)
    end

    # 
    class DefaultSet
      def process(config)
        config.status_db_dsn = "sqlite://" + File.expand_path('tmp/wakame.db', config.root_path)
      end
    end

    class EC2 < DefaultSet
      def process(config)
        super(config)
        config.config_root = File.join(config.root_path, 'tmp', 'config')

        config.ssh_private_key = '/home/wakame/config/root.id_rsa'

      end
    end

    class StandAlone < DefaultSet
      def process(config)
        super(config)
        config.config_root = File.join(config.root_path, 'tmp', 'config')
        config.amqp_server_uri = 'amqp://localhost/'
      end
    end

  end

end
