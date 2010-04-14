
require 'shellwords'
require 'ext/shellwords' unless Shellwords.respond_to? :shellescape
require 'fileutils'

class Wakame::Actor::System
  include Wakame::Actor

  def sync(count = 1)
    count.to_i.times do |i|
      Wakame.log.debug("Wakame::Actor::System.sync #{i + 1}/#{count}")
      Wakame::Util.exec("/bin/sync")
    end
  end

  def mount(dev, path, opts={})
    Wakame.log.debug("Wakame::Actor::System.mount")
    cond = ConditionalWait.new { |c|
      c.poll {
        self.sync
        File.blockdev?(dev)
      }
    }
    cond.wait

    raise "#{dev} does not exist or not block device." unless File.blockdev?(dev)
    raise "#{path} does not exist or not directory."   unless File.directory?(path)
    
    mount_point_dev=`/bin/df "#{path}" | /usr/bin/awk 'NR==2 {print $1}'`.strip
    Wakame.log.debug("#{mount_point_dev}: #{dev}, /bin/mount | awk '$3==path {print $1}' path=\"#{path}\"")
    if mount_point_dev != dev
      Wakame.log.debug("Mounting volume: #{dev} as #{path} (with options: #{opts})")
      Wakame::Util.exec("/bin/mount #{escape_mount_opts(opts)} '#{Shellwords.shellescape(dev)}' '#{Shellwords.shellescape(path)}'")
    else
      Wakame.log.debug("Mounting EBS volume: #{dev} as #{path} (with options: #{opts})")
    end
  end

  def umount(path)
    raise "#{path} does not exist or not directory." unless File.directory?(path)

    mount_point_dev=`/bin/df "#{path}" | awk 'NR==2 {print $1}'`
    Wakame.log.debug("Unmounting volume: #{mount_point_dev} on #{path}")
    Wakame::Util.exec("/bin/umount '#{Shellwords.shellescape(path)}'")
  end

  def touch(path)
    FileUtils.touch(path)
  end
  
  private
  def escape_mount_opts(opts)
    return '' if opts.nil?
    return "-o '#{Shellwords.shellescape(opts)}'" if opts.is_a? String

    out = opts.collect { |k,v|
      v.nil? ? k : "#{k}=#{v}"
    }.join(',')
    "-o #{Shellwords.shellescape(out)}"
  end

end

