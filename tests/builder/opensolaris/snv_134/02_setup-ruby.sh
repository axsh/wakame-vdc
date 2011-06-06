#!/bin/sh

export LANG=C
export LC_ALL=C
export PATH=/usr/gnu/bin:/usr/bin:/usr/sbin:/sbin
#/bin:/usr/bin:/sbin:/usr/sbin

unset GEM_HOME
unset GEM_PATH
unset RUBYOPT


# wakame account
getent group  wakame >/dev/null || {
  groupadd wakame
}

getent passwd wakame >/dev/null || {
  useradd -d /export/home/wakame -s /bin/bash -g wakame -m wakame
}

#[ -f /export/home/wakame/.bash_profile ] || {
  cat <<'EOS' > /export/home/wakame/.bash_profile
export GEM_HOME=/export/home/wakame/.gem/ruby/1.8
export GEM_PATH=${GEM_HOME}
export PATH=/usr/gnu/bin:/usr/bin:/usr/sbin:/sbin:${GEM_HOME}/bin:/opt/git/bin
EOS
  chown wakame:wakame /export/home/wakame/.bash_profile
#}

  cat <<'EOS' > /export/home/wakame/.gemrc
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
gemhome: /export/home/wakame/.gem/ruby/1.8
gempath:
- /export/home/wakame/.gem/ruby/1.8
EOS
  chown wakame:wakame /export/home/wakame/.gemrc

egrep ^wakame /etc/sudoers >/dev/null || {
  echo "wakame  ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
}


{
cat <<EOS
cd /tmp
wget http://production.cf.rubygems.org/rubygems/rubygems-update-1.3.7.gem
gem install rubygems-update-1.3.7.gem  --no-ri --no-rdoc
[ -f rubygems-update-1.3.7.gem ] && rm -f rubygems-update-1.3.7.gem
sudo /export/home/wakame/.gem/ruby/1.8/bin/update_rubygems
EOS
} | su - wakame -c /usr/bin/bash

exit 0
