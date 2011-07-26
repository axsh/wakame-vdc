#!/bin/sh

export LANG=C
export LC_ALL=C
export PATH=/bin:/usr/bin:/sbin:/usr/sbin

unset GEM_HOME
unset GEM_PATH
unset RUBYOPT

pkgs="
 SUNWruby18
 SUNWgmake
 SUNWgcc
 SUNWiscsitgt
 SUNWgit
"

for pkg in ${pkgs}; do
  pkg install ${pkg}
done


svcadm enable svc:/system/iscsitgt:default


exit 0
