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
