## Overview

In Wakame-vdc it is possible to take a running [instance](../jargon-dictionary.md#instance) and turn it into a new [machine image](../jargon-dictionary.md#machine-image). We simply call this process *backup*.

This is a quick and easy way to create new machine images. For example, you could start up an instance, install a web server in it and then back it up. Now you'll have a machine image with a web server installed and you'll immediately be able to start a any amount of web server instances.

## Requirements

You of course need a working Wakame-vdc installation. You can use either the [VirtualBox demo image](http://wakameusersgroup.org/demo_image.html) or create your own environment using the [installation guide](../installation.md).

You need to tell Wakame-vdc which [backup storage](../jargon-dictionary.md#backup-storage) to use when backing up instances. Both the VirtualBox image and the installation guide will set that up but just in case, here it is again.

Figure out which backup storage you want to use with `vdc-manage`.

```bash
/opt/axsh/wakame-vdc/dcmgr/bin/vdc-manage backupstorage show
```

On an environment installed according to the installation guide, it will have this output

```bash
UUID            Storage Type         Base URI
bkst-local      local                file:///var/lib/wakame-vdc/images/
```

There's only one backup storage defined and its UUID is `bkst-local`. We need to make sure this is set in `dcmgr.conf`.

```bash
grep backup_storage_id /etc/wakame-vdc/dcmgr.conf
```

That command should have an output similar to this.

```bash
backup_storage_id 'bkst-local'
```

If it does not show the UUID of the backup storage you want to use, open the file with a text editor and change that line.


## Usage

You need to have started an [instance](../jargon-dictionary.md#instance) in order to back it up. If you don't know how to start an instance, you can find the instructions in [the basic usage guide](../usage/index.md).

Before you can create a backup, you have to power off your instance. On the Instances page of the GUI, tick the checkbox next to your instance and click on `Select an Action`.

![screenshot](img/instance-backup/01_select_an_action.png)

Next, click on `Power Off`.

**Remark**

Make sure to click on `Power Off` and not `Stop`. `Stop` will delete the instance while keeping its ip address and memory etc. reserved. When starting it again afterwards, it will run a new instance in its place.

`Power Off` means that the instance's OS will get the shutdown signal and the instance will gracefully shut down. It is equivalent to shutting down a physical server. You will be able to `Power On` the same instance again later.

![screenshot](img/instance-backup/02_power_off.png)

Your instance should now have the state of `halting`. Wait a few moments and click on the `Refresh` button. Repeat until your instance has reached the state of `halted`.

![screenshot](img/instance-backup/03_halting.png)

Now tick the checkbox next to your instance again and click `Backup`.

![screenshot](img/instance-backup/04_backup.png)

The `Create Instance Backup` dialog will pop up. Fill in the `Backup Display Name` field. This will become the name of your new [machine image](../jargon-dictionary.md#machine-image). Click on `Backup` when you've filled it in.

![screenshot](img/instance-backup/05_create_backup_dialog.png)

You'll be taken back to the instances page. Click on `Machine Images` in the menu on the left.

![screenshot](img/instance-backup/06_instance_after_backup.png)

You should see your new machine image with the state of `creating`. Wait a few moments and click on `Refresh`. Eventually your image will reach the state of `available`.

![screenshot](img/instance-backup/07_machine_image_creating.png)

Once your image has reached the state of `available`, you are done. You are now free to `Power On` the original instance again and/or start new instances of this machine image.

![screenshot](img/instance-backup/08_create_image_available.png)

