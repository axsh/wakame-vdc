

require 'fileutils'

namespace :xen do
  task :start_vm do
    puts "xm create hogefuga"
    sleep 10
  end

  task :stop_vm do
    puts "xm destroy hogefuga"
    sleep 3
  end

  task :start_vm2 do
    # prepare image store directory for new instance.
    img_basedir = File.expand_path("#{options['instance_uuid']}", Wakame.config.image_deployment_base_dir)
    raise "the instance already exists: #{options['instance_uuid']}" if File.exists? img_basedir
    FileUtils.mkdir_p(img_basedir)

    # copy image file from the src image store.
    os_img_path = File.expand_path('os.img', img_basedir)
    if system("curl --silent -f -I '#{options['image_storage_uri']}.gz'")
      Wakame::Util.exec("curl --silent '#{options['image_storage_uri']}.gz' | zcat > '#{os_img_path}'")
      #Wakame::Util.exec("gunzip  '#{os_img_path}.gz'")
    else
      Wakame::Util.exec("curl --silent -o '#{os_img_path}' '#{options['image_storage_uri']}'")
    end
    # setup ephemeral/swap devs
    #Wakame::Util.exec("/bin/dd if=/dev/zero of=#{} count=#{} bs=1M")

    xen_conf = File.expand_path(options['instance_uuid'], img_basedir)

    vnic = options['vnic'].map{|i| "mac=#{i['mac']}, bridge=#{i['bridge']}" }
    # create xen config file under the img_basedir.
    File.open(xen_conf, 'w') { |f|
      f << <<__XEN_CONF__
name        = '#{options["instance_uuid"]}'
memory      = #{options["memory"].to_i}
vcpus       = #{options["cpus"]}
bootroader  = '/usr/bin/pygrub'
root        = '/dev/xvda ro'
vfb         = [ ]
disk        = [ 'tap:aio:#{os_img_path},xvda,w' ]
vif         = [ #{vnic.map{|i| '\'' + i + '\''}.join(', ')} ]
on_poweroff = 'destroy'
on_reboot   = 'restart'
on_crash    = 'restart'
__XEN_CONF__
    }

    Wakame::Util.exec("xm create #{xen_conf}")
  end
end
