## Overview

Wakame has functionality
specifically for supporting Windows, both for creating Windows seed image and for running and using multiple Windows instances in a Wakame environment. The use of Windows on Wakame-vdc is significantly different from the use of Linux instances.

For creating seed images, certain steps are necessary to make installations of Windows compatible with Wakame-vdc.  The main requirement is that virtio drivers must be installed, because Windows instances are always run in KVM virtual machines.  To make working with multiple instances possible, a special initialization script must also be installed, so that Wakame-vdc can coordinate with the Windows OS.

When launching new instances, Microsoft requires that its Windows sysprep utility be used.  This requirement affects both seed image creation and how instances are launched and backed up.  In addition, there are various configuration options that can be set when starting Windows instances, such as initial passwords, firewall options, product keys, and automatic activation.

In order to make getting started with Windows as easy as possible, Wakame-vdc includes scripts that can create working Windows seed images automatically.  The only preparation necessary is to download a Windows installation ISO image from microsoft.com, or copy one from a Windows Installation DVD.  The seed images are created using a default configuration that should work well for many Windows-on-Wakame-vdc applications.  The details of the scripts provide a known-to-work example that should greatly accelerate the efforts of users who need to work out customized configurations.

## Default Configuration

## Image Creation Scripts

### Initial Setup

The scripts for building seed images are part of the Wakame-vdc repository, so the first
step is to clone this repository from github and change to the directory for
building Windows images.

```bash
git clone https://github.com/axsh/wakame-vdc
cd wakame-vdc/vmapp/windows-image-build/
```

Next, a Microsoft Windows install image must be copied to the
`./resources/` directory.  The scripts have tested OK with images from
`http://www.microsoft.com/`.  Currently, only Japanese images are
supported. (English versions will be supported *very* soon.)

The next step is to create a "build directory" that will hold the
new seed image and various other files particular to one image build.
We do this with the general purpose `build-dir-utils.sh` script.

```bash
./build-dir-utils.sh builddirs/manual-build-2008/ 0-init 2008
```

The directory `builddirs` should already exist as part of the Wakame-vdc
repository.  The above command should create a new directory
named `manual-build-2008`.  The third parameter (2008, in the example)
is required and specifies which version of Windows will be installed.

Next, specific settings for building the image are applied to the
build directory.  A list of these can be found in the file
`windows-image-build.ini`.  The default values should work, except for
the ISO file name and the product key, which must be set.  This can be
done by editing the file or by setting shell environment variables.

```bash
# the following was used in a recent test
export ISO2008=7601.17514.101119-1850_x64fre_server_eval_ja-jp-GRMSXEVAL_JA_DVD.iso
export KEY2008=none
./build-dir-utils.sh builddirs/manual-build-2008/ 1-setup-install
```

In addition, the `1-setup-install` step checks to make sure all needed
resources are in the `./resources/` directory.  If any are missing, an
attempt will be made to download them.  The settings from
`windows-image-build.ini` and environment variables that are gathered
during this step will be used through the rest of the image
installation process.

### Partially Automatic Image Creation

From this point, the image creation proceeds with multiple calls to
the same `build-dir-utils.sh` script.  Always, the first argument is
the build directory and the second argument is the name of the build
step.  Because the build steps must be performed in order, the name of
each step is prefixed with a number to indicate the ordering.

Some of the build steps must be performed in the Windows user
interface, and sometimes the best way to do these steps is manually.
Therefore, some of the steps are just placeholders for actions that a
user would do manually, and the script itself actually does not
perform any action that affects the VM or Windows OS.  In this way,
the steps themselves can serve as a concise documentation of *all* the
steps necessary to build a Windows image.  The `build-dir-utils.sh`
script both automates steps that are easy to automates, and helps the
user not to forget those steps that are easier to perform manually.

To make this easier, after the 0-init step, it is possible to go
through the rest of the build issuing either one of the following
commands:

```bash
./build-dir-utils.sh builddirs/manual-build-2008/ -do-next
  ## OR ##
./build-dir-utils.sh builddirs/manual-build-2008/ -done
```

The `-do-next` parameter tells the build scripts to do the next
easy-to-automate step.  The `-done` option tells the build scripts
that the required manual step has been done.  Internally, the scripts
keep track of what to do next (or what to confirm has been done) by
looking in the file `nextstep` in the build directory.  Step that must
be confirmed always contain the 3 characters "-M-" in their step
names.  The contents of `nextstep` is automatically updated to keep
track of progress.  The output from each invocation gives feedback
about what needs to be done to continue to the next installation step.

A formatted log of all the steps and corresponding outputs can be seen
by following this link[[TODO]].

### Automatic Image Creation

Sometimes even the manual steps required by `./build-dir-utils.sh` can
be automated.  When this is the case, the whole process of building
Windows images can be automated.  The Wakame-vdc repository includes a
script that can do all the manual steps by doing simple pattern
matching on KVM screen shots and simulating mouse and keyboard actions
by way of KVM's VNC interface.  An example invocation would be as
follows:

```bash
./build-dir-utils.sh builddirs/automatic-build-2008/ 0-init 2008
export ISO2008=7601.17514.101119-1850_x64fre_server_eval_ja-jp-GRMSXEVAL_JA_DVD.iso
export KEY2008=none
./utils/auto-windows-image-build.sh builddirs/automatic-build-2008/ --package
```

The screen pattern technique depends on the particular ISO file being
used, so different patterns are used depending on whether a 2008 or
2012 image is being created.  The script has been tested successfully
on Japanese trial images from `http://www.microsoft.com/`.

## Wakame-vdc with KVM

Windows on Wakame-vdc requires that KVM be used as the hypervisor.
The current [installation guide](../installation.md) only explains how
to use OpenVZ as the hypervisor.  For using KVM, the installation
procedure is different in only a few ways.

One difference is that it is strongly recommended that installation of
KVM-based Wakame-vdc be on bare-metal hardware.  In other words, the
Wakame-vdc installation should not be nested inside another virtual
machine, because nested virtualization is sometimes not possible, and
even when possible, performance is often very bad.

A second difference is that `wakame-vdc-hva-openvz-vmapp-config`
should not be installed.  Instead, install the following:

```bash
sudo yum install -y wakame-vdc-hva-kvm-vmapp-config
```

The third difference is that registration of HVA should be changed to do
`--hypervisor kvm`:

```bash
/opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage host add hva.demo1 \
   --uuid hn-demo1 \
   --display-name "demo HVA 1" \
   --cpu-cores 100 \
   --memory-size 10240 \
   --hypervisor kvm \
   --arch x86_64 \
   --disk-space 102400 \
   --force
```

One additional installation is needed for retrieving the initial
password for logging into a Windows instance.  This is the `mussel`
utility program, which can be installed with the following:

```bash
sudo yum install -y --disablerepo=updates wakame-vdc-client-mussel
```

## Installing Windows Images

For either partially automatic or fully automatic images builds, the
resulting Wakame-vdc machine images are place in the build directory
in a sub-directory named `final-seed-image`.  The listing below shows
that both qcow2.gz and raw.tar.gz versions of the images were made.
In this section we will explain how to install the raw.tar.gz version.

```bash
$ ls -l builddirs/automatic-build-2008/final-seed-image/
total 13190744
-rw-r--r-- 1 triggers triggers          47 Oct  7 19:43 win-2008.raw.md5
-rw-r--r-- 1 triggers triggers  3055007405 Oct  7 20:00 windows2008r2.x86_64.15071.qcow2.gz
-rw-r--r-- 1 triggers triggers          70 Oct  7 20:07 windows2008r2.x86_64.15071.qcow2.gz.md5
-rw-r--r-- 1 triggers triggers          67 Oct  7 20:00 windows2008r2.x86_64.15071.qcow2.md5
-rw-r--r-- 1 triggers triggers 32212254720 Oct  7 19:52 windows2008r2.x86_64.kvm.md.raw
-rw-r--r-- 1 triggers triggers  3050428633 Oct  7 20:00 windows2008r2.x86_64.kvm.md.raw.tar.gz
-rw-r--r-- 1 triggers triggers        1025 Oct  7 20:00 windows2008r2.x86_64.kvm.md.raw.tar.gz.install.sh
-rw-r--r-- 1 triggers triggers          73 Oct  7 20:00 windows2008r2.x86_64.kvm.md.raw.tar.gz.md5
```

The first step for installing an image is to move its `*raw.tar.gz` file
to Wakame-vdc's directory for keeping images.

```bash
sudo mkdir -p /var/lib/wakame-vdc/images # if it does not exist already
sudo cp builddirs/automatic-build-2008/final-seed-image/windows2008r2.x86_64.kvm.md.raw.tar.gz \
     /var/lib/wakame-vdc/images
```

Next, the image needs to be registered as a backup object in
Wakame-vdc's database.  Assuming an KVM-based installation as
described above, the following command shows the necessary parameters.
Note that the parameter values will be different for each specific
image.

```bash
/opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage backupobject add \
  --uuid=bo-windows2008r2 \
  --account-id=a-shpoolxx \
  --storage-id=bkst-local \
  --display-name="windows2008r2 30G" \
  --object-key=windows2008r2.x86_64.kvm.md.raw.tar.gz \
  --container-format=tgz \
  --size=32212254720 \
  --allocation-size=3050428633 \
  --checksum=17c696598a69760ac1110f1418b1bbea
```

Next, the backup object is registered as a machine image.

```bash
/opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage image add local bo-windows2008r2 \
  --uuid=wmi-windows2008r2 \
  --account-id=a-shpoolxx \
  --arch=x86_64 \
  --description="windows2008r2.x86_64.kvm.md.raw.tar.gz local" \
  --file-format=raw \
  --root-device=label:root \
  --service-type=std \
  --display-name="windows2008r2 30G" \
  --is-public \
  --is-cacheable
```

The above two commands are basically the same as commands for
registering an OpenVZ image.  The next two commands specify
options that are only used for Windows instances:

```bash
/opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage image features wmi-windows2008r2 --virtio
/opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage image modify wmi-windows2008r2 --os-type=windows
```

To help with doing the above commands, the `build-dir-utils.sh` script
also generates an `*.install.sh` script that contains the above
commands with the correct parameter values for the newly generated
image.  Therefore instead of the four commands above, the following
can used to register the backup object and machine image:

```bash
bash ./builddirs/automatic-build-2008/final-seed-image/windows2008r2.x86_64.kvm.md.raw.tar.gz.install.sh \
   backupobject image
```

## Launching Windows Instances

The procedure for launching a Windows instance is almost the same as
the procedure for OpenVZ instances that is shown in [basic usage
guide](./index.md).  Only three differences need to be mentioned.

The first difference is that the "Instance Spec:" setting on the
"Launch Instance" dialog window.  It should be set to `kvm.xlarge`,
because the KVM hypervisor is required and Windows instances require
more memory than Linux instances.

The second difference is that the security group should include the
setting `tcp:3389,3389,ip4:0.0.0.0`.  Port 3389 is used by remote
desktop, which is the preferred technique for logging into and
interacting with the Windows graphical user interface.  Opening port 3389
allows remote desktop clients to connect to Windows.

The third difference is that the ssh key is a hard requirement.
Launching will fail if no key is selected. Although ssh keys are set
up and selected in the same way as when launching Linux instances, it
is used differently, as will be explained in the next section.

## Logging into Window Instances

After launching a Windows instance, the Wakame-vdc web GUI will show
that the instance's state is *initializing*.  This is the same
behavior as with Linux instances, however, Windows instances stay in
the *initializing* state for a longer time, because the machine image
starts out in a sysprepped state and therefore must go through a time
consuming *first-boot* initialization procedure.

After about 10 minutes (or longer depending on the speed of the host
machine and its load), the state should change to running.  Now
Windows starts a second boot, and soon (after about 30 seconds) it
starts the remote desktop server.  At this point it should be possible
to log in.  Connecting to the instance's IP address with any remote
desktop client should show the Windows *cltr-alt-delete* screen.  To
log in to a new instance for the first time, use the user name
*Administrator* and the initial password.  How to find out what the
initial password is is explained next.

During first-boot, a special Wakame-vdc initialization script
generates a random initial password and sets it to the *Administrator*
account.  Then the password is encrypted using the ssh key and put in
the Wakame-vdc database.  Therefore, only a user with the private part
of the ssh key pair can learn the password.

Currently, the easiest way to retrieve the initial password is by
using the `mussel` utility.  It has a feature that fetches the
encrypted password from the database and decrypts it with the given
key.  It can be invoked on the machine hosting Wakame-vdc as shown
here:

```bash
$ mussel instance decrypt_password i-mrdw5pcf ssh-cbixzm91.pem
wvh?^A&}&}
```

The instance uuid is the third parameters and the fourth parameter is
the private part of the ssh key that was selected when launching the
instance.  For this example, the password is `wvh?^A&}&}`.

In the future, functionality to retrieve the initial random password will
be added to the Wakame-vdc web GUI.
