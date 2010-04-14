require 'rbconfig'

class WakameGenerator < RubiGen::Base

  DEFAULT_SHEBANG = File.join(Config::CONFIG['bindir'],
                              Config::CONFIG['ruby_install_name'])

  # Installation skeleton.  Intermediate directories are automatically
  # created so don't sweat their absence here.
  BASEDIRS = %w(
    bin
    cluster
    cluster/actors
    cluster/actions
    cluster/triggers
    cluster/resources
    cluster/resources/markers
    cluster/commands
    config
    config/init.d
    config/environments
    lib
    tasks
    tmp
    vendor
  )

  default_options   :shebang => DEFAULT_SHEBANG,
  :bin_name    => nil,
  :import_path => nil,
  :version     => '0.0.1'


  attr_reader :gem_name, :module_name, :project_name
  attr_reader :version, :version_str

  # extensions/option
  attr_reader :bin_names_list

  def initialize(runtime_args, runtime_options = {})
    super(config_args_and_runtime_args(runtime_args), runtime_options)
    usage if args.empty?
    @destination_root = File.expand_path(args.shift)
    @gem_name = base_name
    @module_name  = gem_name.gsub('-','_').camelize
    @project_name = @gem_name
    extract_options
  end

  def manifest
    # Use /usr/bin/env if no special shebang was specified
    script_options = { :chmod => 0755, :shebang => options[:shebang] == DEFAULT_SHEBANG ? nil : options[:shebang] }
    windows        = (RUBY_PLATFORM =~ /dos|win32|cygwin/i) || (RUBY_PLATFORM =~ /(:?mswin|mingw)/)
    source_dir     = source_path('.').sub(%r{/\.\Z}, '')

    record do |m|
      # Root directory and all subdirectories.
      m.directory ''
      BASEDIRS.each { |path| m.directory path }

      m.file_copy_each %w(Rakefile README)
      m.file_copy_each %w(config/boot.rb config/cluster.rb config/environments/common.rb config/environments/stand_alone.rb  config/environments/ec2.rb
                          cluster/resources/markers/http_application_server.rb
                          cluster/resources/markers/http_asset_server.rb
                          cluster/resources/markers/http_server.rb)
      m.dependency "install_rubigen_scripts", [destination_root, :wakame]

      %w(wakame-master wakame-agent wakameadm).each do |script|
        m.template "bin/#{script}", "bin/#{script}", script_options
      end
      %w(wakame-master wakame-agent).each do |script|
        m.template "config/init.d/#{script}", "config/init.d/#{script}", script_options
      end
      
    end
  end

  protected
  def banner
    <<-EOS
Usage: #{File.basename $0} /path/to/your/app [options]
EOS
  end

  def add_options!(opts)
    opts.separator ''
    opts.separator 'Options:'
    opts.on("-b", "--bin-name=BIN_NAME[,BIN_NAME2]", String,
            "Sets up executable scripts in the bin folder.",
            "Default: none") { |x| options[:bin_name] = x }
    opts.on("-i", "--install=generator", String,
            "Installs a generator called install_<generator>.",
            "For example, '-i cucumber' runs the install_cucumber generator.",
            "Can be used multiple times for different generators.",
            "Cannot be used for generators that require argumnts.",
            "Default: none") do |generator|
      options[:install] ||= []
      options[:install] << generator
    end
    opts.on("-p", "--project=PROJECT", String,
            "Rubyforge project name for the gem you are creating.",
            "Default: same as gem name") { |x| options[:project] = x }
    opts.on("-r", "--ruby=path", String,
            "Path to the Ruby binary of your choice (otherwise scripts use env, dispatchers current path).",
            "Default: #{DEFAULT_SHEBANG}") { |x| options[:shebang] = x }
    opts.on("-v", "--version", "Show the #{File.basename($0)} version number and quit.")
  end

  def extract_options
    @version           = options[:version].to_s.split(/\./)
    @version_str       = @version.join('.')

    @bin_names_list     = (options[:bin_name] || "").split(',')
    @project_name       = options[:project] if options.include?(:project)
    @install_generators = options[:install] || []
  end
  
  # first attempt to merge config args (single string) and runtime args
  def config_args_and_runtime_args(runtime_args)
    newgem_config = File.expand_path(File.join(ENV['HOME'], '.newgem.yml'))
    if File.exists?(newgem_config)
      config = YAML.load(File.read(newgem_config))
      if config_args = (config["default"] || config[config.keys.first])
        return config_args.split(" ") + runtime_args
      end
    end
    runtime_args
  end

end
