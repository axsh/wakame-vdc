Installing RPM Builder Software
-------------------------------

### Donwloading Wakame-VDC

    # git clone git://github.com/axsh/wakame-vdc.git

### Installing Base Packages to Build RPMs

vdc.sh installs base packages to build RPMs.

    # cd ./wakame-vdc/
    # ./tests/vdc.sh install::rhel

Building Wakame-VDC RPMs
------------------------

### Building RPMs using Makefile

rules is GNU Makefile. this is based on debian/rule.

    # ./rpmbuild/rules binary

Installing Wakame-VDC RPMs
--------------------------

    # yum install /root/rpmbuild/RPMS/x86_64/wakame-vdc-*.rpm

Developing Wakame-VDC RPMs
--------------------------

### Deploying Wakame-VDC

    $ [ -d ~/rpmbuild/BUILD/ ] || mkdir -p ~/rpmbuild/BUILD/
    $ cd ~/rpmbuild/BUILD/
    $ git clone git://github.com/axsh/wakame-vdc.git wakame-vdc-15.03
    $ cd wakame-vdc-15.03

### Modifying files.

    $ vi ./path/to/file...

#### Building RPMs using SPEC.

    $ rpmbuild -bc --short-circuit ./rpmbuild/SPECS/wakame-vdc.spec
    $ rpmbuild -bb --short-circuit ./rpmbuild/SPECS/wakame-vdc.spec
