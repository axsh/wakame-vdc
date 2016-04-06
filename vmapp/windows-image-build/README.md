# Overview

The main two scripts are `build-w-answerfile-floppy.sh` and
`windows-image-smoke-test.sh`.  The first script evolved over time to
automate various things that were useful when building Windows images
and debugging PowerShell scripts.  It focuses on things that were easy
to automate and has many commands and options.  It can be used by
itself, but it does not automate everything.

In contrast, `windows-image-smoke-test.sh` is a script that was
written quickly.  Its purpose is to wrap
`build-w-answerfile-floppy.sh` with a simple interface that is easy to
integrate into Jenkins.  One consequence of this is that it must automate everything
including user interface actions inside of Windows, which it does by
using `supernext.sh` and `kvm-ui-util.sh`.

## The `bash` script files:

### build-w-answerfile-floppy.sh

This script's main functions are starting and stopping Windows VMs and
dealing with the images files.  One typical use is to boot a VM, do
something interactively with the VM, and then record some log files
from the VM, then more manually start sysprep, then record more log
files, etc.  To make sending multiple commands to the same VM easier,
a persistent *build directory* is associated with a Windows image.  It
keeps track of details like the KVM ports so that such low-level
details do not need to be repeated for each command.

The *build directory* also serves other purposes:

  1. It provides a place to archive a collection of log files for later debugging.
  
  2. It facilitates running multiple experiments simultaneously, each
  in a separate build directory.

  3. It provides a place for tracking multi-step testing scenarios.

This last purpose is important for understanding how the other scripts
work.  `build-w-answerfile-floppy.sh` contains a set of numbered
commands, which if done in order, walk through the steps of a particular
debugging scenario that has been useful.  A file in the build
directory named `nextstep` always contains the name of the command for
the next step, which can be invoked automatically by calling the
script like this:

```
$ ./build-w-answerfile-floppy.sh /path/to/builddir -next
```

Between the steps, manual actions are usually needed.  By doing these
actions and invoking the above command line, a developer can reliably
run through a test scenario that is time-consuming,
tedious, and otherwise easy to mess up.

### windows-image-smoke-test.sh

To make things easy for Jenkins, this script does three things.
First, it makes sure all the extra files that are required by
`build-w-answerfile-floppy.sh` (such as the Windows install DVD ISO
image) are available.  Then it creates a new build directory.  Then it
calls `build-w-answerfile-floppy.sh` until it has completed the first
three steps of the scenario, which are the steps that install Windows.

### supernext.sh

This script is used by `windows-image-smoke-test.sh` to simulate user
interface actions that are not automated by
`build-w-answerfile-floppy.sh`.  It relies on the `nextstep` file to
know what actions need to be done.

### kvm-ui-util.sh

This is a low-level script that is used to simulate user actions in
KVM.  It is only called by `supernext.sh`, although a little setup
code for its use is in `build-w-answerfile-floppy.sh`.  This script
has potential for reuse in other project.

## The other files

### Autounattend-08.xml & Autounattend-12.xml

One of these is put on a floppy image (and renamed to
Autounattend.xml) when booting from the Windows install DVD ISO.  The
file gives the Windows installer enough information to proceed
automatically until KVM is booted with a fresh install of Windows.

### FinalStepsForInstall.cmd

This batch file script is run by the Windows installer based on
instructions from Autounattend.xml.  It copies all of the Wakame-vdc
boot scripts to c:\Windows\Setup\Scripts\.  This includes all the
*.xml, *.cmd, and *.ps1 files in this directory not described here.

### run-sysprep.cmd

After the Windows installer and FinalStepsForInstall.cmd have finished
running, it is necessary to log in to the VM (using "a:run-sysprep" as
the Administrator password) and run this script to finish making the
seed image.  This script is copied to the floppy image, so it is
can be invoked by typing a:run-sysprep into a console window.  It does a
little setup and then runs the sysprep command with the correct
parameters.  Note that the build-w-answerfile-floppy.sh sometimes
modifies this batch file on-the-fly so that it installs zabbix before
running sysprep.

# Running locally:

## Copy the following resource files to this directory (or follow alternative instructions given below):

* Windows installation ISO files for Windows Server 2008 and 2012
* virtio-win-0.1-74.iso (from http://alt.fedoraproject.org/pub/alt/virtio-win/)
* zabbix_agent-1.8.15-1.JP_installer.exe (from http://repo.zabbix.jp/zabbix/zabbix-1.8/windows/)
* An example metadata.img image in a tar file named metadata.img.tar.gz
* Files named key2008 and key2012, with the Windows 5x5 activation keys on one line

## Remember path to this directory.

```
$ SDIR="$(pwd)"
```

* And then in a writable directory somewhere run the script with 2008
  or 2012 as the parameter:

```
$ $SDIR/windows-image-smoke-test.sh 2008
```

This will create a new build directory named ./builddirs/smoketest-2008 or
./builddirs/smoketest-2012, build a seed image there, and confirm that
the file `C:\Windows\Setup\State\State.ini` indicates sysprep ran correctly.

# Automatic download of resource files

The `windows-image-smoke-test.sh` script provides an automatic
download feature that is convenient for Jenkins.  Instead of manually
putting the files in the directory, put the required files in an
Amazon S3 bucket and do the following:

  * Create a `~/.s3cfg` that gives enough permissions to access the bucket.
  * In the shell do: export S3URL=s3://a.b.c.d/the/path/to/the/iso/files

As an alternative to putting the sensitive key2008 and key2012 files in S3,
the following is also possible.

```
export JenkinsENV_key2008="aaaaa-bbbbb-ccccc-ddddd-eeeee"  # key for Windows Server 2008
export JenkinsENV_key2012="fffff-ggggg-hhhhh-iiiii-jjjjj"  # key for Windows Server 2012
```

Then running the same command as above will first download the needed
resources and then build the seed image:

```
$ $SDIR/windows-image-smoke-test.sh 2008
```

# Final packaging

To create a seed image that is ready to be used with Wakame-vdc, do
the following command steps manually:

 ```
$ $SDIR/build-w-answerfile-floppy.sh  /path/to/builddirs/smoketest-2008  3-tar-the-image
$ $SDIR/build-w-answerfile-floppy.sh  /path/to/builddirs/smoketest-2008  -package
```

The ready-to-use images will be created at
/path/to/builddirs/smoketest-2008/final-seed-image/windows2008r2.x86_64.kvm.md.raw.tar.gz.
