#!/bin/sh
#
# Ubuntu 10.04 LTS
#

export LANG=C
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive
export PATH=/bin:/usr/bin:/sbin:/usr/sbin

unset GEM_HOME
unset GEM_PATH
unset RUBYOPT


# wakame account
getent group  wakame >/dev/null || {
  groupadd wakame
}

getent passwd wakame >/dev/null || {
  useradd -d /home/wakame -s /bin/bash -g wakame -m wakame
}

#[ -f /home/wakame/.bash_profile ] || {
# always overwrite.
  cat <<'EOS' > /home/wakame/.bash_profile
export GEM_HOME=/home/wakame/.gem/ruby/1.8
export GEM_PATH=${GEM_HOME}
export PATH=${PATH}:${GEM_HOME}/bin
EOS
  chown wakame:wakame /home/wakame/.bash_profile
#}

  cat <<'EOS' > /home/wakame/.gemrc
---
:benchmark: false
gem: --no-rdoc --no-ri
:update_sources: true
:verbose: true
:backtrace: false
:sources:
- http://gems.rubyforge.org/
- http://gems.github.com
:bulk_threshold: 1000
gemhome: /home/wakame/.gem/ruby/1.8
gempath:
- /home/wakame/.gem/ruby/1.8

EOS
  chown wakame:wakame /home/wakame/.gemrc

egrep -q ^wakame /etc/sudoers || {
  echo "wakame  ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
}


exit 0
