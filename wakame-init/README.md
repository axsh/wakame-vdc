How to build deb package.
===


System requirements.
---
* OS: Ubuntu 14.04.2


Required packages.
---
* git
* build-essential
* devscripts
* cdbs
* debhelper

install packages
```
$ sudo apt-get install git build-essential devscripts cdbs debhelpers
```

Build deb package.
---

git clone wakame-vdc 
```
$ git clone https://github.com/axsh/wakame-vdc.git
```

change directory
```
$ cd wakame-vdc/wakame-init
```

build package.
```
$ debuild --no-tgz-check -uc -us
```

created package.
```
$ ls -la ../ | grep wakame-init_*
drwxrwxr-x  5 vagrant vagrant 4096 Mar 13 10:31 wakame-init
-rw-r--r--  1 vagrant vagrant 4580 Mar 13 10:32 wakame-init_13.08-1_all.deb
-rw-r--r--  1 vagrant vagrant 4707 Mar 13 10:32 wakame-init_13.08-1_amd64.build
-rw-r--r--  1 vagrant vagrant 1154 Mar 13 10:32 wakame-init_13.08-1_amd64.changes
-rw-r--r--  1 vagrant vagrant  515 Mar 13 10:31 wakame-init_13.08-1.dsc
-rw-r--r--  1 vagrant vagrant 5594 Mar 13 10:31 wakame-init_13.08-1.tar.gz

```

crean build dir
```
$ fakeroot debian/rules clean
test -x debian/rules
dh_clean
```
