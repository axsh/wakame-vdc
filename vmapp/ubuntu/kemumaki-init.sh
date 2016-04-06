#!/bin/bash
#
# requires:
#  bash
#
set -e
set -o pipefail
set -x

mnt_path=${mnt_path:-mnt}
raw=${raw:-$(pwd)/box-disk1.raw}
passwd_login=${passwd_login:-enabled}

[[ -f ${raw} ]]
[[ $UID == 0 ]]

# remove tail "/".
mnt_path=${mnt_path%/}

mkdir -p ${mnt_path}

output=$(kpartx -va ${raw})
loopdev_root=$(echo "${output}" | awk '{print $3}' | sed -n 1,1p) # loopXp1 should be "root".
loopdev_swap=$(echo "${output}" | awk '{print $3}' | sed -n 2,2p) # loopXp2 should be "swap".
[[ -n "${loopdev_root}" ]]
udevadm settle

devpath=/dev/mapper/${loopdev_root}
trap "
 umount -f ${mnt_path}/dev
 umount -f ${mnt_path}/proc
 umount -f ${mnt_path}
" ERR

e2label ${devpath} root

mount ${devpath} ${mnt_path}
mount --bind /proc ${mnt_path}/proc
mount --bind /dev  ${mnt_path}/dev


function render_tty_conf() {
  cat <<-'EOS'
# tty1 - getty
#
# This service maintains a getty on tty1 from the point the system is
# started until it is shut down again.

start on stopped rc RUNLEVEL=[2345] and (
            not-container or
            container CONTAINER=lxc or
            container CONTAINER=lxc-libvirt)

stop on runlevel [!2345]

respawn
exec /sbin/getty -8 38400 ttyS0 vt102
EOS
}

function render_autologin_conf() {
  cat <<-'EOS'
	[Service]
	ExecStart=
	ExecStart=-/sbin/agetty --autologin=root -s %I
	EOS
}

function config_tty() {
  # upstart
  if [[ -f ${mnt_path}/etc/init/tty.conf ]]; then
    render_tty_conf | tee ${mnt_path}/etc/init/tty.conf
  fi

  # systemd
  if [[   -d ${mnt_path}/etc/systemd/system/getty.target.wants ]]; then
    mkdir -p ${mnt_path}/etc/systemd/system/getty\@ttyS0.service.d
    render_autologin_conf | tee ${mnt_path}/etc/systemd/system/getty\@ttyS0.service.d/autologin.conf
  fi
}


config_tty

if [[ -d execscript ]]; then
  while read line; do
    eval ${line} ${mnt_path} ${passwd_login}
  done < <(find -L execscript ! -type d -perm -a=x | sort)
fi

if [[ -d guestroot ]]; then
  rsync -avxSL guestroot/ ${mnt_path}/
fi

sync

##

umount ${mnt_path}/dev
umount ${mnt_path}/proc
umount ${mnt_path}
kpartx -vd ${raw}

sleep 3

function detach_partition() {
  local loopdev=${1}
  [[ -n "${loopdev}" ]] || return 0

  if dmsetup info ${loopdev} 2>/dev/null | egrep ^State: | egrep -w ACTIVE -q; then
    dmsetup remove ${loopdev}
  fi

  udevadm settle

  local loopdev_path=/dev/${loopdev%p[0-9]*}
  if losetup -a | egrep ^${loopdev_path}: -q; then
    losetup -d ${loopdev_path}
  fi
}

detach_partition ${loopdev_root}
detach_partition ${loopdev_swap}
