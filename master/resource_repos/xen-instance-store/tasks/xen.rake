

require 'fileutils'

namespace :xen do

  task :start_vm do
    # prepare image store directory for new instance.
    img_basedir = File.expand_path("#{$instance_data[:vm_instance_id]}",
                                   $manifest.config.image_deployment_base_dir)
    raise "the instance already exists: #{$instance_data[:vm_instance_id]}" if File.exists? img_basedir
    FileUtils.mkdir_p(img_basedir)

    # copy image file from the src image store.
    os_img_path = File.expand_path('os.img', img_basedir)
    if sh("curl --silent -f -I '#{$instance_data[:image_storage_uri]}.gz'")
      sh("curl --silent '#{$instance_data[:image_storage_uri]}.gz' | zcat > '#{os_img_path}'")
    else
      sh("curl --silent -o '#{os_img_path}' '#{$instance_data[:image_storage_uri]}'")
    end
    # setup ephemeral/swap devs
    #sh("/bin/dd if=/dev/zero of=#{} count=#{} bs=1M")

    xen_conf = File.expand_path('xen.conf', img_basedir)

    vnic = $instance_data[:vnic].map{|i| "mac=#{i[:mac]}, bridge=#{i[:bridge]}" }
    # create xen config file under the img_basedir.
    File.open(xen_conf, 'w') { |f|
      f << <<__XEN_CONF__
name        = '#{$instance_data[:vm_instance_id]}'
memory      = #{$instance_data[:memory].to_i}
vcpus       = #{$instance_data[:cpus]}
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

    sh("xm create #{xen_conf}")
  end


  task :stop_vm do
    img_basedir = File.expand_path("#{$instance_data[:vm_instance_id]}",
                                   $manifest.config.image_deployment_base_dir)
    
    sh("xm destroy '#{$instance_data[:vm_instance_id]}'")
    sleep 5
    FileUtils.rm_rf(img_basedir)
  end
  
end
