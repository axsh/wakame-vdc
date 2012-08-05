Continuous Build RPMs
=====================

      +--------+
      | GitHub |
      +--------+
          |
          | git pull
          V
     +----------+  s3cmd   +--------+  yum install  +------------+
     |build node| -------> |yum repo| <===========> | Wakame-VDC |
     +----------+          +--------+               +------------+
          | A
    chroot| | rsync
          V |
       +---------+
       |mini rhel| rpmbuild
       +---------+


Installation Requirements
-------------------------

### System Requiremenets

+ RHEL 6.x
+ Ubuntu 12.04 LTS

#### Ubuntu 12.04 LTS

+ git
+ s3cmd
+ yum
+ createrepo

### Network Requirements

+ Local Area Network (LAN)
+ Internet connection


Pre-setup CI sandbox
--------------------

### s3cmd

In order to upload RPMs to Wakame-VDC yum repository.

    $ sudo s3cmd --configure


### CI sandbox

    $ git clone git://github.com/axsh/wakame-vdc.git
    $ cd wakame-vdc/rpmbuild/ops/
    $ ./setup-ci-env.sh


### Once checking to build RPMs.

    $ sudo ./periodic-build.sh hourly


Continuous Build
----------------

Under the screen environment, building rpms.

    $ screen
    screen$ cd ~/work/ci/wakame-vdc/rpmbuild/ops/
    screen$ while date; do time sudo ./periodic-build.sh hourly; date; sleep 60; done
