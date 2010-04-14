class ResourceGenerator < RubiGen::Base
  DEFAULT_SHEBANG = File.join(Config::CONFIG['bindir'],
                              Config::CONFIG['ruby_install_name'])

  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    @resource_template = args.shift
    @resource_name = nil
    @resource_name = args.shift unless args.empty?
  end

  def manifest
    # Use /usr/bin/env if no special shebang was specified
    script_options     = { :chmod => 0755, :shebang => options[:shebang] == DEFAULT_SHEBANG ? nil : options[:shebang] }
    windows            = (RUBY_PLATFORM =~ /dos|win32|cygwin/i) || (RUBY_PLATFORM =~ /(:?mswin|mingw)/)

    source_dir     = source_path('.').sub(%r{/\.\Z}, '')

    fail "[ERROR] The resource folder does not exist: #{@resource_template}" unless File.directory? source_path(@resource_template)
    @resource_name ||= @resource_template

    record do |m|
      # Create the resource name folder
      m.directory File.join('cluster', 'resources', @resource_name)
      Dir.glob(source_path(@resource_template) + "/**/*").each { |path|
        relpath =  path.sub(%r{\A#{source_root}\/}, '')

        if File.directory? path
          m.directory File.join('cluster', 'resources', relpath)
        else
          m.file relpath, File.join('cluster', 'resources', relpath)
        end
      }
    end
  end


  protected
  def banner
    templates = Dir.glob(spec.path + "/templates/*").collect { |path|
      File.basename(path)
    }

    <<-EOS
Generate a wakame resource folder under cluster/resources/.

USAGE: #{$0} resource "resource template name" [resource instance name]

Installed Templates:
#{templates.join(', ')}

EOS
  end

end
