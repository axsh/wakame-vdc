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


### Automatic Image Creation

## Installing Windows Images

## Launching Windows Instances

