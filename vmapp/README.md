### Re-organize Image file generation process

Folder Structure:

```
vmapp/
|
+- build.sh
+- build.sh.d/ # installing & configurating packages
+- functions/  # utility functions
|
+- load_balancer/ # load-balancer vmapp
|  +- amqptool/
|  +- etc/
|  +- scripts/
|  +- execscript.sh
|  +- image.ini
|  +- copy.txt
|  +- README
|
+- vanilla/ # vmapp for unit/integration test
|  +- execscript.sh
|  +- image.ini
|  +- copy.txt
|  +- README
|
+- test/ # tests for vmapp scripts
   +- shunit2
   +- unit/
   +- integration/
   +- vmapp/
```

build.sh is the user interface for building new image file. The script calls vmbuilder script set with configurations based on image.ini.

User will type command as per below:

```
% cd vmapp
% ./build.sh load_balancer
```

For customizing image file, each service folder has execscript.sh which is applied to chrooted rootfs tree. vmbuilder + image.ini will build the base image file also be responsible on making special changes for target hypervisor. execscript.sh will take care for later changes, such as installing additional packages or updating configuration files.

execscript.sh

```
#!/bin/bash
#
# requires:
#  bash
#
# imports:
#  functions: install_wakame_init
#
set -e

### include files

# Every execscript must load common function file.
. ${ROOTPATH}/functions.sh

# chroot directory is given in first argument.
declare chroot_dir=$1

## main
# Do some changes......
```
