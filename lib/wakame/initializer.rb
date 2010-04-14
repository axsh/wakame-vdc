
WAKAME_ENV = (ENV['WAKAME_ENV'] || 'StandAlone').dup.to_sym unless defined?(WAKAME_ENV)

module Wakame
  class Initializer

    class << self
      def run(command, configuration=Configuration.new)
        @instance ||= new(configuration)
        @instance.send(command)
      end

      def instance
        @instance
      end

      def loaded_classes
        @loaded_classes ||= []
      end
    end

    attr_reader :configuration

    def initialize(configuration)
      @configuration = configuration
    end

    def process
      setup_load_paths
      setup_logger
      load_environment
    end

    def process_master
      require 'wakame/master'
      setup_database
      load_resources
      load_core_commands
      load_core_actions
      load_core_triggers
    end
    
    def process_agent
      require 'wakame/agent'
      load_actors
      load_monitors
    end
    
    def process_cli
      process
    end

    def setup_load_paths
      load_paths = configuration.load_paths + configuration.project_paths + configuration.framework_paths
      load_paths.reverse_each { |dir| $LOAD_PATH.unshift(dir) if File.directory?(dir) }
      $LOAD_PATH.uniq!

      require 'wakame'
    end

    def setup_logger
      require 'log4r'
      Logger.log = begin
                     #log = Logger.new((Wakame.root||Dir.pwd) / "log.log")
                     out = ::Log4r::StdoutOutputter.new('stdout',
                                                        :formatter => Log4r::PatternFormatter.new(
                                                                                                  :depth => 9999, # stack trace depth
                                                                                                  :pattern => "%d %C [%l]: %M",
                                                                                                  :date_format => "%Y/%m/%d %H:%M:%S"
                                                                                                  )
                                                        )
                     log = ::Log4r::Logger.new(File.basename($0.to_s))
                     log.add(out)
                     log
                   end
    end


    def setup_system_actors
    end

    def load_system_monitors
    end

    def load_core_commands
#       %w( cluster/commands ).each { |load_path|
#         load_path = File.expand_path(load_path, configuration.root_path)
#         matcher = /\A#{Regexp.escape(load_path)}(.*)\.rb\Z/
#         Dir.glob("#{load_path}/**/*.rb").sort.each do |file|
#           require file.sub(matcher, '\1')
#         end
#       }

      load_framework('wakame/command/**/*.rb', lambda{ |f|
                       Wakame.log.debug("Loading Core Commands: #{f}")
                     })
    end


    def load_environment
      config = configuration
      constants = self.class.constants

      [:common, config.environment].each { |key|
        eval(IO.read(config.environment_path(key)), binding, config.environment_path(key))
      }

      (self.class.constants - constants).each do |const|
        Object.const_set(const, self.class.const_get(const))
      end
    end

    def load_resources
      load_path = File.expand_path('cluster/resources/markers', configuration.root_path)
      Dir.glob("#{load_path}/*.rb").sort.each do |file|
        Wakame.log.debug("Loading resource marker: #{file}")
        load file
      end
      
      load_path = File.expand_path('cluster/resources', configuration.root_path)
      Dir.glob("#{load_path}/*/*.rb").sort.each do |file|
        if file =~ %r{\A#{Regexp.escape(load_path)}/([^/]+)/([^/]+)\.rb\Z} && $1 == $2
          Wakame.log.debug("Loading resource definition: #{file}")
          load file
        end
        #require file.sub(matcher, '\1')
      end
    end

    def load_actors
      load_framework('wakame/actor/**/*.rb', lambda{ |f|
                       Wakame.log.debug("Loading Core Actor: #{f}")
                     })

      load_project('cluster/actors/*.rb', lambda{ |f|
                     Wakame.log.debug("Loading Project Actor: #{f}")
                   })
    end

    def load_monitors
      load_framework('wakame/monitor/**/*.rb', lambda{ |f|
                       Wakame.log.debug("Loading Core Monitor: #{f}")
                     })

      #load_project('cluster/monitors/*.rb', lambda{ |f|
      #               Wakame.log.debug("Loading Project Monitor: #{f}")
      #             })
    end

    def load_core_triggers
      load_framework("wakame/triggers/**/*.rb", lambda{ |f|
                       Wakame.log.debug("Loading Core triggers: #{f}")
                     })
    end

    def load_core_actions
      load_framework("wakame/actions/**/*.rb", lambda{ |f|
                       Wakame.log.debug("Loading Core Actions: #{f}")
                     })
    end

    def setup_database
      require 'sequel'
      
      #db = Sequel.connect(Wakame.config.status_db_dsn, {:logger=>Wakame.log})
      #db = Sequel.connect(Wakame.config.status_db_dsn, {:timeout=>15000})
      db = Sequel.connect(Wakame.config.status_db_dsn)
      if db.uri  =~ /\Asqlite:/
        orig_proc = db.pool.connection_proc
        db.pool.connection_proc = proc { |svr|
          con = orig_proc.call(svr)
          con.busy_handler {|data, retries|
            if retries > 5
              Wakame.log.fatal("Detected the SQLite's busy lock: #{Thread.current}, data=#{data}, retries=#{retries}")
              exit 100
            end
            sleep 8
            true
          }
          con
        }
      end

      load_framework('wakame/models/*.rb', 
                     lambda {|path| self.class.loaded_classes.clear},
                     lambda {|path|
                               
                       self.class.loaded_classes.each { |model_class|
                         next unless model_class.is_a?(Class) && model_class < Sequel::Model
                         
                         model_class.create_table?
                       }

                     })


      if db.table_exists?(:metadata)
      else
        db.create_table? :metadata do
          primary_key :id
          column :version, :string
          column :created_at, :datetime
        end
        db[:metadata].insert(:version=>'0.4', :created_at=>Time.now)
      end

    end

    def load_framework(glob_pat, pre_hook=nil, post_hook=nil)
      if Wakame::Bootstrap.boot_type == Wakame::Bootstrap::VendorBoot
        rbfiles = Dir.glob(File.expand_path(glob_pat, File.join(configuration.framework_root_path, 'lib')))  
      else
        rbfiles = Gem.find_files(glob_pat)
      end
      rbfiles.sort.each{ |f|
        pre_hook.call(f) if pre_hook
        load f
        post_hook.call(f) if post_hook
      }
    end

    def load_project(glob_pat, pre_hook=nil, post_hook=nil)
      Dir.glob(File.expand_path(glob_pat, configuration.root_path)).sort.each{ |f|
        (pre_hook.call(f) || next) if pre_hook
        load f
        post_hook.call(f) if post_hook
      }
    end

  end
end
