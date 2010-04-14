
require 'fileutils'
require 'erb'
require 'pathname'

module Wakame
  class Template
    attr_accessor :service_instance
    attr_reader :tmp_basedir

    def initialize(service_instance)
      @service_instance = service_instance
      @tmp_basedir = File.expand_path(Util.gen_id, File.join(Wakame.config.root_path, 'tmp', 'config') )
      FileUtils.mkdir_p @tmp_basedir
    end

    def basedir
      @service_instance.resource.basedir
    end

    def glob_basedir(glob_patterns, &blk)
      glob_patterns = [glob_patterns] if glob_patterns.is_a? String

      basedir_obj = Pathname.new(basedir)
      paths = glob_patterns.collect {|pattern| Pathname.glob(File.join(basedir, pattern)).collect {|path| path.relative_path_from(basedir_obj) } }
      paths = paths.flatten.uniq

      paths.each &blk if blk

      paths
    end

    def render_config
      service_instance.resource.render_config(self)
    end

    def cleanup
      FileUtils.rm_r( @tmp_basedir, :force=>true)
    end

    def render(path)
      update(path) { |buf|
        ERB.new(buf, nil, '-').result(service_instance.export_binding)
      }
    end

    def cp(path)
      destpath = File.expand_path(path, @tmp_basedir)
      FileUtils.mkpath(File.dirname(destpath)) unless File.directory?(File.dirname(destpath))
      
      FileUtils.cp_r(File.join(basedir, path),
                     destpath,
                     {:preserve=>true}
                     )
    end

    def chmod(path, mode)
      File.chmod(mode, File.join(@tmp_basedir, path))
    end

    def load(path)
      path = path.sub(/^\//, '')
      
      return File.readlines(File.expand_path(path, basedir), "r").join('')
    end
    
    def save(path, buf)
      path = path.sub(/^\//, '')
      
      destpath = File.expand_path(path, @tmp_basedir)
      FileUtils.mkpath(File.dirname(destpath)) unless File.directory?(File.dirname(destpath))
      
      File.open(destpath, "w", 0644) { |f|
        f.write(buf)
      }
    end
    
    def update(path, &blk)
      buf = load(path)
      buf = yield buf if block_given?
      save(path, buf)
    end
    
  end
  
end
