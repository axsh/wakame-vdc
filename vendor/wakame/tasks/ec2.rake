#!/usr/bin/env ruby

#require 'wakame'
require 'timeout'

#AWS_ACCESS_KEY=ENV['AMAZON_ACCESS_KEY_ID'] || Wakame.config.aws_access_key
#AWS_SECRET_KEY=ENV['AMAZON_SECRET_ACCESS_KEY'] || Wakame.config.aws_secret_key
AWS_ACCESS_KEY=ENV['AMAZON_ACCESS_KEY_ID']
AWS_SECRET_KEY=ENV['AMAZON_SECRET_ACCESS_KEY']

def create_ec2
  require 'EC2'
  ec2 = EC2::Base.new(:access_key_id =>AWS_ACCESS_KEY, :secret_access_key =>AWS_SECRET_KEY)
end

def request_metadata_url(key)
  require 'open-uri'
  open("http://169.254.169.254/2008-09-01/meta-data/#{key}") { |f|
    return f.readline
  }
end

namespace :ec2 do
  desc "Automate the EC2 image bundle procedure.(ec2-bundle-vol + ec2-upload-bundle + ec2-register)"
  task :bundle, :manifest_path do |t, args|
    raise 'This task requires root privilege.' unless Process.uid == 0
    raise 'Required key files counld not be detected: /mnt/cert.pem or /mnt/pk.pem'  unless File.exist?('/mnt/cert.pem') && File.exist?('/mnt/pk.pem')

    #sh("/etc/init.d/rabbitmq-server stop") rescue puts $!

    bundle_tmpdir='/mnt/wakame-bundle'
    # If the arg was not set, it tries to overwrite the running image.
    manifest_path= args.manifest_path || request_metadata_url('ami-manifest-path')

    #manifest_path.sub!(/.manifest.xml\Z/, '')
    if manifest_path =~ %r{\A([^/]+)/(.+)\.manifest\.xml\Z}
      #s3bucket = manifest_path[0, manifest_path.index('/') - 1]
      #manifest_prefix = manifest_path[manifest_path.index('/')]
      s3bucket = $1
      manifest_basename = File.basename($2)
      manifest_path = "#{s3bucket}/#{manifest_basename}.manifest.xml"
      #puts "#{manifest_path}"
    else
      fail "Given manifest path is not valid: #{manifest_path}"
    end

    puts "Manifest Path: #{manifest_path}"
    
    ec2 = create_ec2()

    ami_id = request_metadata_url('ami-id')

    instance_id = request_metadata_url('instance-id')
    res = ec2.describe_instances(:instance_id=>instance_id)
    account_no = res['reservationSet']['item'][0]['ownerId']

    res = ec2.describe_images(:image_id=>ami_id)
    arch = res['imagesSet']['item'][0]['architecture']

    begin
      FileUtils.rm_rf(bundle_tmpdir) if File.exist?(bundle_tmpdir)
      FileUtils.mkpath(bundle_tmpdir)

      sh("ec2-bundle-vol --batch -d '#{bundle_tmpdir}' -p '#{manifest_basename}' -c /mnt/cert.pem -k /mnt/pk.pem -u '#{account_no}' -r '#{arch}'")
      sh("ec2-upload-bundle -d '#{bundle_tmpdir}' -b '#{s3bucket}' -m '#{File.join(bundle_tmpdir, manifest_basename + '.manifest.xml')}' -a '#{AWS_ACCESS_KEY}' -s '#{AWS_SECRET_KEY}'")
      res = ec2.register_image(:image_location=>manifest_path)
      puts "New AMI ID for #{manifest_path}: #{res['imageId']}"
    ensure
      FileUtils.rm_rf(bundle_tmpdir) if File.exist?(bundle_tmpdir)
    end
  end


  desc "Initiate the mysql master volume using Amazon EBS"
  task :mysqlsetupvol, :size do |t, args|
    raise 'This task requires root privilege.' unless Process.uid == 0

    ATTACH_DEV='/dev/sdw'
    TMP_MNT='/mnt/mysql-tmp'
    vol_size = (args.size || '1').to_s
    zone = request_metadata_url('placement/availability-zone')
    instance_id = request_metadata_url('instance-id')

    ec2 = create_ec2
    res = ec2.create_volume(:size=>vol_size, :availability_zone=>zone)
    vol_id = res['volumeId']
    
    timeout(10) {
      begin
        res = ec2.describe_volumes(:volume_id=>vol_id)
        next if res['volumeSet']['item'][0]['status'] == 'available'
        sleep 0.5
        retry
      end
    }

    begin
      res = ec2.attach_volume(:instance_id=>instance_id, :volume_id=>vol_id, :device=>ATTACH_DEV)
      
      timeout(10) {
        begin
          res = ec2.describe_volumes(:volume_id=>vol_id)
          next if res['volumeSet']['item'][0]['status'] == 'in-use' && File.blockdev?(ATTACH_DEV)
          sleep 0.5
          retry
        end
      }
      
      sh("echo 'y' | mkfs.ext3 -q #{ATTACH_DEV}")
      
      begin
        FileUtils.mkpath(TMP_MNT) unless File.exist?(TMP_MNT)
        sh("mount #{ATTACH_DEV} #{TMP_MNT}")
        sleep 1.0
        sh("/usr/bin/mysql_install_db --datadir=#{TMP_MNT}")
      ensure
        sh("umount #{TMP_MNT}")
        sleep 1.0
      end

    ensure
      ec2.detach_volume(:volume_id=>vol_id, :instance_id=>instance_id) rescue puts $!
    end

    puts "Initialized EBS Volume: #{vol_id} "
  end
end
