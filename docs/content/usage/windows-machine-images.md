## Overview

Wakame has functionality
specifically for supporting Windows, both for creating Windows seed image and for running and using multiple Windows instances in a Wakame environment. The use of Windows on Wakame-vdc is significantly different from the use of Linux instances.

For creating seed images, certain steps are necessary to make installations of Windows compatible with Wakame-vdc.  The main requirement is that virtio drivers must be installed, because Windows instances are always run in KVM virtual machines.  To make working with multiple instances possible, a special initialization script must also be installed, so that Wakame-vdc can coordinate with the Windows OS.

When launching new instances, Microsoft requires that its Windows sysprep utility be used.  This requirement affects both seed image creation and how instances are launched and backed up.  In addition, there are various configuration options that can be set when starting Windows instances, such as initial passwords, firewall options, product keys, and automatic activations.

In order to make getting started with Windows as easy as possible, Wakame-vdc includes scripts that can create working Windows seed images automatically.  The only preparation necessary is to download a Windows installation ISO image from microsoft.com, or copy one from a Windows Installation DVD.  The seed images are created using a default configuration that should work well for many Windows on Wakame-vdc applications.  The details of the scripts provide a known-to-work example that should greatly accelerate the efforts of users to need to work out customized configurations.

## Default Configuration

## Image Creation Scripts

```bash
git clone test.mkdoc...
cd a/b/c/
```

## Automatic Image Creation

## Installing Windows Images

## Launching Windows Instances

