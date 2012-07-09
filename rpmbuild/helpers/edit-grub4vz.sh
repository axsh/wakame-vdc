#!/bin/bash

set -e
set -x

pkg_name=vzkernel
root_dev=$(awk '$2 == "/" {print $1}' /etc/fstab)

rpm -qi ${pkg_name} >/dev/null || { echo "not available: ${pkg_name}" >&2; exit 1; }

kernel_version=$(rpm -qi ${pkg_name} | egrep ^Version | awk '{print $3}')
kernel_release=$(rpm -qi ${pkg_name} | egrep ^Release | awk '{print $3}')
grub_title="OpenVZ (${kernel_version}-${kernel_release})"
grub_title_regex="OpenVZ \(${kernel_version}-${kernel_release}\)"

case "$1" in
add)
  egrep ^title /boot/grub/grub.conf | grep "${grub_title}" -q && {
    echo "already exists: ${grub_title}"
    exit 0
  }

  cat <<EOS >> /boot/grub/grub.conf
title ${grub_title}
        root (hd0,0)
        kernel /boot/vmlinuz-${kernel_version}-${kernel_release} ro root=${root_dev} rd_NO_LUKS rd_NO_LVM LANG=en_US.UTF-8 rd_NO_MD SYSFONT=latarcyrheb-sun16 crashkernel=auto  KEYBOARDTYPE=pc KEYTABLE=us rd_NO_DM
        initrd /boot/initramfs-${kernel_version}-${kernel_release}.img
EOS
  ;;

del)
  grub_line_from=$(egrep -n "${grub_title_regex}" /boot/grub/grub.conf | awk -F: '{print $1}')
  [ -z "${grub_line_from}" ] && {
    echo "no such line: ${grub_title_regex}" >&2
    exit 1
  }
  grub_line_to=$(egrep -n "^title" /boot/grub/grub.conf | awk -F: '{print $1}' | egrep -w ${grub_line_from} -A 1 | tail -1)

  [ -z "${grub_line_to}" ] && {
    grub_line_to=\$
  } || {
    if [ "${grub_line_to}" = "${grub_line_from}" ]; then
      grub_line_to=\$
    else
      grub_line_to=$((grub_line_to - 1))
    fi
  }

  sed -i "${grub_line_from},${grub_line_to}d" /boot/grub/grub.conf

  menu_offset=0
  sed -i "s,^default=.*,default=${menu_offset}," /boot/grub/grub.conf
  ;;

enable)
  menu_order=$(egrep ^title /boot/grub/grub.conf | cat -n | grep "${grub_title}" | tail | awk '{print $1}')
  [ -z ${menu_order} ] && {
    menu_offset=0
  } || {
    menu_offset=$((${menu_order} - 1))
  }
  sed -i "s,^default=.*,default=${menu_offset}," /boot/grub/grub.conf
  ;;

*)
  echo "$0 [ add | del ]"
  ;;
esac

cat /boot/grub/grub.conf
