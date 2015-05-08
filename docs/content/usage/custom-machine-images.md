## Custom Machine Images

Although there are a variety of pre-built machine images for Wakame-vdc, in
most cases it will be necessary to install extra software and do other
miscellaneous setup after starting an [instance](../jargon-dictionary.md#instance).  To reduce this setup
effort, in some cases it makes sense for users to create their own
custom [machine images](../jargon-dictionary.md#machine-image).  Then by simply starting an instance in Wakame-vdc, it is
possible to have a virtual machine up and running that is already
perfectly set up.  All necessary software and services, for whatever
purpose, can be "ready-to-go".

There are five basic steps for creating and using a custom machine image with Wakame-vdc:

1. Install an OS into a bootable disk or directory structure.

2. Specialize the OS installation for the intended purpose.

3. Specialize the OS installation for Wakame-vdc.

4. Package it all into one machine image file.

5. Register this machine image file with Wakame-vdc.

Wakame-vdc supports various virtualization technologies (KVM, OpenVZ,
and LXC) and methods of packaging (tar, gzip, disk partitions, etc.),
and the details for doing the above steps depends on which are chosen.
Below we will explain the steps assuming OpenVZ virtualization and gz
packaging, and to make things a little more interesting, set up the
machine image to automatically start up a web server with a single
static web page to show.  The steps for other combinations are
similar, but differ in subtle ways that will be documented later.


#### Step 1: Install an OS into a bootable disk or directory structure

For OpenVZ, specialized techniques are required to install an OS, so
the recommended procedure is to use one of the *precreated templates*
that can be found at the [OpenVZ wiki](https://wiki.openvz.org/Download/template/precreated).  Minimal
installations of the major Linux distributions are available.

#### Step 2: Specialize the OS installation for the intended purpose

The most straightforward way to install and configure the installed OS
distribution is from inside OpenVZ itself.  An environment created by
following the [installation guide](../installation.md) or the [VirtualBox
demo image guide](http://wakameusersgroup.org/demo_image.html) provides
enough OpenVZ functionality to do this.

As an example, running
following shell commands in a VM booted with the demo image will
download a minimal "template cache" for CentOS and specialize it by installing web server
software.  For an example of miscellaneous configuration, the shell commands
create a top Web page and set up the web service to automatically start when the
machine image is instantiated.


The first few commands log into the demo VM and download a template image:

    ssh centos@a.b.c.d  # where a.b.c.d is the demo VM's IP address
    [centos@wakame-vdc-1box ~]$ sudo su
    [root@wakame-vdc-1box centos]# cd /vz/template/cache
    [root@wakame-vdc-1box cache]# wget http://download.openvz.org/template/precreated/centos-6-x86_64-minimal.tar.gz

Next, an OpenVZ container based on this image is started.
Note that the 101 that appears many times below can be any number that
is not in use by OpenVZ.

    [root@wakame-vdc-1box cache]# vzctl create 101 --ostemplate centos-6-x86_64-minimal --ipadd a.b.c.vv --hostname localhost
    [root@wakame-vdc-1box cache]# vzctl set 101 --nameserver 8.8.8.8 --save
    [root@wakame-vdc-1box cache]# vzctl start 101

Now we can go inside the container and specialize it by installing and
configuring software.

    [root@wakame-vdc-1box cache]# vzctl enter 101
    [root@localhost /]# yum install httpd
    [root@localhost /]# echo "<html>An Example top web page.</html>" >/var/www/html/index.html
    [root@localhost /]# service httpd start
    [root@localhost /]# chkconfig httpd on

#### Step 3: Specialize the OS installation for Wakame-vdc


##### Insert the wakame-init script and run it from /etc/rc.local:

Note: This step is necessary so that Wakame-vdc can do last-minute
specialization that is necessary when each instance is booted.  For
example, the wakame-init script sets up network addresses and routing
and installs ssh keys.  It also ensures that instances can access
information from special [meta-data](../jargon-dictionary.md#meta-data) storage.
One use of this storage is to allow scripts inside an instance to do
additional specialization based on
[user-data](../jargon-dictionary.md#user-data).  Users can enter this data
on-the-fly while starting an instance, and scripts can read it from a
special file at `/metadata/user-data`.

    curl -o /etc/yum.repos.d/wakame-vdc.repo -R https://raw.githubusercontent.com/axsh/wakame-vdc/master/rpmbuild/wakame-vdc.repo

    yum install -y wakame-init

##### Clear shell history:

Note: This step is optional.

    rm /home/*/.bash_history /root/.bash_history

##### Remove ssh host keys:

Note: This step is optional but recommended so that different
instances appear as different ssh hosts.

    rm /etc/ssh/ssh_host*

##### Remove net rules file so eth0 doesn't become eth1 at start:

Note: This step is not necessary for OpenVZ, but will not cause any
problems.  In fact, most of the OpenVZ precreated template caches do
not have this file.

    rm /etc/udev/rules.d/70-persistent-net.rules

#### Step 4: Package it all into one machine image file

Exit the OpenVZ container.

    [root@localhost etc]# exit

Now we are back at the demo box prompt. The following instructions are adapted from
the [OpenVZ wiki](http://wiki.openvz.org/Updating_Ubuntu_template):

    [root@wakame-vdc-1box cache]# vzctl stop 101
    [root@wakame-vdc-1box cache]# vzctl set 101 --ipdel all --save
    [root@wakame-vdc-1box cache]# cd /vz/private/101
    [root@wakame-vdc-1box 101]# tar  --numeric-owner -czf /vz/template/cache/new-custom-image-temp.tar.gz .
    [root@wakame-vdc-1box 101]# cd ..
    [root@wakame-vdc-1box private]# vzctl destroy 101

Wakame-vdc's preferred method of packaging machine images is inside of
partitioned VM images files. The following commands show one way to
create such an image file and store the new customized OS distribution
inside it using standard GNU/Linux commands.

The first commands change to the `/var/lib/wakame-vdc/images/`
directory and create a 10G empty image there. Other directories will
work. The advantage of choosing this directory is so that the image
file will already be in the right place for testing with Wakame-vdc.

    [root@wakame-vdc-1box private]# cd /var/lib/wakame-vdc/images/
    [root@wakame-vdc-1box images]# truncate -s 10G wakame-vdc-custom-image.raw

The next commands add a partition table to the image, and then make
the first partition be an ext2 partition (i.e. which in this context,
means any Linux partition) that takes up the whole image, except
the first 63 sectors.  The new unformatted partition is then mounted
on a loop device.

    [root@wakame-vdc-1box images]# parted wakame-vdc-custom-image.raw mklabel msdos
    [root@wakame-vdc-1box images]# parted --script -- wakame-vdc-custom-image.raw mkpart primary ext2 63s -0
    [root@wakame-vdc-1box images]# kpartx -va wakame-vdc-custom-image.raw

Next, the mounted partition is formatted and then mounted.  Note:
Before doing this next command, be sure the output from previous
kpartx command says that the partition was mounted at loop0p1, and if
not adjust the parameter accordingly.

    [root@wakame-vdc-1box images]# mkfs.ext4 -F -E lazy_itable_init=1 -L root /dev/mapper/loop0p1
    [root@wakame-vdc-1box images]# tune2fs -o acl /dev/mapper/loop0p1
    [root@wakame-vdc-1box images]# mkdir tmp-mount
    [root@wakame-vdc-1box images]# mount /dev/mapper/loop0p1 tmp-mount/

Next, we copy the OpenVZ directory contents into the file system and
then unmount the file system.

    [root@wakame-vdc-1box images]# cd tmp-mount/
    [root@wakame-vdc-1box tmp-mount]# tar xzf /vz/template/cache/new-custom-image-temp.tar.gz
    [root@wakame-vdc-1box tmp-mount]# cd ..
    [root@wakame-vdc-1box images]# umount tmp-mount/
    [root@wakame-vdc-1box images]# rmdir tmp-mount/

Because in some use cases disk images can have multiple partitions,
Wakame-vdc needs to know the UUID of the formatted disk partition to
reliably identify it when booting instances.  This UUID needs to be
found before the partition is removed from the loop device, so we
determine it first and then release the loop device.

    [root@wakame-vdc-1box images]# blkid -o export /dev/mapper/loop0p1 | tee /tmp/remember.uuid-etc
    [root@wakame-vdc-1box images]# kpartx -vd wakame-vdc-custom-image.raw

Before compressing the machine image, remember its size.

    [root@wakame-vdc-1box images]# ls -l wakame-vdc-custom-image.raw | awk '{print $5}' | tee /tmp/remember.size

Finally, compress the image and remember the compressed size and the checksum of the compressed machine image.

    [root@wakame-vdc-1box images]# gzip wakame-vdc-custom-image.raw
    [root@wakame-vdc-1box images]# ls -l wakame-vdc-custom-image.raw.gz | awk '{print $5}' | tee /tmp/remember.alloc_size
    [root@wakame-vdc-1box images]# md5sum /var/lib/wakame-vdc/images/wakame-vdc-custom-image.raw.gz | head -c 32 | tee /tmp/remember.md5

#### Step 5: Register this machine image file with Wakame-vdc

First, move the new machine image to Wakame-vdc's directory for keeping
images.  (If the machine image was created by the above steps, it might
already be there.)

    mv wakame-vdc-custom-image.raw.gz /var/lib/wakame-vdc/images

Registering the machine image file requires two vdc-manage commands.
The first registers the file as a [backup object](../jargon-dictionary.md#backup-object) and assigns it to a
[backup storage](../jargon-dictionary.md#backup-storage).  For example, to
register the machine image created above into [backup storage](../jargon-dictionary.md#backup-storage) named `bkst-local`, the
following command could be used:

    /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage backupobject add \
      --uuid bo-customimage \
      --display-name "New image with web server and one static page" \
      --storage-id bkst-local \
      --object-key wakame-vdc-custom-image.raw.gz \
      --size $(cat /tmp/remember.size) \
      --allocation-size $(cat /tmp/remember.alloc_size) \
      --container-format gz \
      --checksum $(cat /tmp/remember.md5)

The second vdc-manage command tells Wakame-vdc that this [backup object](../jargon-dictionary.md#backup-object)
is a machine image that we can start instances of.

    /opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage image add local bo-customimage \
      --account-id a-shpoolxx \
      --uuid wmi-customimage \
      --root-device uuid:$(source /tmp/remember.uuid-etc ; echo $UUID) \
      --display-name "New image with web server and one static page"

Note that the $() expressions here supply the command with necessary
details about the machine image, assuming it was collected as in the example
steps above.  The names `bkst-local` and `a-shpoolxx` will work if
your are installing into an environment that was created by following
the [Wakame-vdc install guide](../installation.md).  The correct values for
other situations can be typed directly into the command line.

### Using and testing the new image

It should now be possible to start an instance from the machine image
by following the instructions in the [basic usage guide](index.md).  The only necessary modification to these instructions
is to use your new image name (such as `customimage` in the example above) instead of lucid5d.
You can find the IP address of your instance from the "Instances" User Interface screen.

If your image came from the instructions on this page, you can confirm that everything
works by doing the following:

1. Add the line "tcp:80,80,ip4:0.0.0.0" to the security group.
2. Point a web browser to the instance's IP address.

The web browser should now be displaying the text: "An Example top web page."



