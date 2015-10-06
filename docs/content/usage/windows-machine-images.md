## Overview

Wakame has functionality
specifically for supporting Windows, both for creating Windows seed image and for running and using multiple Windows instances in a Wakame environment. The use of Windows on Wakame-vdc is significantly different from the use of Linux instances.

For creating seed images, certain steps are necessary to make installations of Windows compatible with Wakame-vdc.  The main requirement is that virtio drivers must be installed, because Windows instances are always run in KVM virtual machines.  To make working with multiple instances possible, a special initialization script must also be installed, so that Wakame-vdc can coordinate with the Windows OS.

When launching new instances, Microsoft requires that its Windows sysprep utility be used.  This requirement affects both seed image creation and how instances are launched and backed up.  In addition, there are various configuration options that can be set when starting Windows instances, such as initial passwords, firewall options, product keys, and automatic activations.

In order to make getting started with Windows as easy as possible, Wakame-vdc includes scripts that can create working Windows seed images automatically.  The only preparation necessary is to download a Windows installation ISO image from microsoft.com, or copy one from a Windows Installation DVD.  The seed images are created using a default configuration that should work well for many Windows-on-Wakame-vdc applications.  The details of the scripts provide a known-to-work example that should greatly accelerate the efforts of users to need to work out customized configurations.

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
repository.  The above command should have created a new directory
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
attempt will be made to download them.  The settings from this step
will be used through the rest of the image installation process.

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
looking in the file `nextstep` in the build directory.  Step names
that contain the 3 characters "-M-" must be confirmed.  The contents
of `nextstep` is automatically updated to keep track of progress.
The output from each invocation gives feedback about what needs to be
done to continue to the next installation step.

A formatted log of all the steps and corresponding outputs can be seen
by following this link[[TODO]].

### Automatic Image Creation

Sometimes even the manual steps required by ./build-dir-utils.sh can
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

## Installing Windows Images

## Launching Windows Instances

