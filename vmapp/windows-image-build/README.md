

Documentation for how to use the scripts in this directory
is at [http://wakame-vdc.org](http://wakame-vdc.org/usage/windows-machine-images/).

Some of specific files are described below:

### build-dir-utils.sh

This script's main functions are starting and stopping Windows VMs and
dealing with the images files.  One typical use is to boot a VM, do
something interactively with the VM, and then record some log files
from the VM, then manually start sysprep, then record more log
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
work.  `build-dir-utils.sh` contains a set of numbered
commands, which if done in order, walk through the steps of a particular
debugging scenario that has been useful.  A file in the build
directory named `nextstep` always contains the name of the command for
the next step, which can be invoked automatically by calling the
script like this:

```
$ ./build-dir-utils.sh /path/to/builddir -do-next
```

Steps that are easier to do manually are also included.  For such
steps, the user does the needed actions and indicates completion by
calling the script like this:

```
$ ./build-dir-utils.sh /path/to/builddir -done
```

By doing these actions and invoking the above command line, a
developer can reliably run through a test scenario that is
time-consuming, tedious, and otherwise easy to mess up.

### auto-windows-image-build.sh

This is an experimental script that attempts to do the
manual steps in `./build-dir-utils.sh`.  It can usually
totally automate the building of Windows images.

### kvm-ui-util.sh

This is a low-level script that is used to simulate user actions in
KVM.  It is only called by `auto-windows-image-build.sh`, although a
little setup code for its use is in `build-dir-utils.sh`.  This script
has potential for reuse in other projects.

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
parameters.  Note that the build-dir-utils.sh sometimes
modifies this batch file on-the-fly so that it installs zabbix before
running sysprep.
