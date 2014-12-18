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
commands, which if done in order, walk through the steps of a
debugging scenario that has been useful.  A file in the build
directory named `nextstep` always contains the name of the command for
the next step, which can be invoked automatically by calling the
script like this:

```
$ ./build-w-answerfile-floppy.sh /path/to/builddir -next
```

Between the steps, manual actions are usually needed.  By doing these
actions and invoking the above command line, a developer can reliably
run through what is otherwise a tedious and error prone test scenario.

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
automatically to a running copy of windows.

### FinalStepsForInstall.cmd

This batch file script is run by the Windows installer based on
instructions from Autounattend.xml.  It copies all of the Wakame-vdc
boot scripts to c:\Windows\Setup\Scripts\.  This includes all the
*.xml, *.cmd, and *.ps1 files in this directory not described here.

### run-sysprep.cmd

After the Windows installer and FinalStepsForInstall.cmd have finished
running, it is necessary to log in to the VM (using "a:run-sysprep" as
the Administrator password) and run this script to finish making the
seed image.  The script is copied to the floppy image, so it is
invoked by typing a:run-sysprep into a console window.  It does a
little setup and then runs the sysprep command with the correct
parameters.  Note that the build-w-answerfile-floppy.sh sometimes
modifies this batch file on-the-fly so that it installs zabbix before
running sysprep.


# ((The information on the rest of this page is out-of-date.))

Windows Image Build Instructions 
================================

* Copy Windows installation ISO files to this directory.
* Copy virtio-win-0.1-74.iso (from http://alt.fedoraproject.org/pub/alt/virtio-win/) to this directory.
* Remember path to this directory.

```
$ SDIR="$(pwd)"
```

* Make a new working directory somewhere and continue as follows:

```
$ mkdir build2008
$ cd build2008
$ echo "aaaaa-bbbbb-ccccc-ddddd-eeeee" >keyfile  # enter Windows 5x5 key
$ $SDIR/build-w-answerfile-floppy.sh 2008 0-init
$ $SDIR/build-w-answerfile-floppy.sh 2008 -next  # shortcut for 1-install
```

* For 2008, connect vncviewer to port number 6080.
* Wait for the Ctrl-Alt-Del login screen to appear in VNC, then do:

```
$ $SDIR/build-w-answerfile-floppy.sh 2008 -next  # shortcut for 1b-record-logs-at-ctr-alt-delete-prompt-gen0
```
* Login to Windows with the password "a:run-sysprep".
* Open PowerShell console and run the helper script for running sysprep by entering a:run-sysprep.
* Wait for the VNC window to disconnect.

```
$ $SDIR/build-w-answerfile-floppy.sh 2008 -next  # shortcut for 2-confirm-sysprep-gen0
```

* The above will confirm that the KVM process has terminated and prompt
you for whether sysprep succeeded.  If KVM did terminate, then sysprep
probably shutdown Windows and KVM after running correctly.  Type "YES"
to continue.

```
$ $SDIR/build-w-answerfile-floppy.sh 2008 -next  # shortcut for 3-tar-the-image
```

* Md5sum will be run on the new Windows seed image, and the image and checksum will be
tarred into a sparse archive.

* Finished.

Instructions for 2012 are the same, except substitute 2012 where 2008
appears and use VNC port number 6090.
