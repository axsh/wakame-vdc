# qemu-build

``qemu-build`` is an image building script inspired by packer-qemu driver.
This program run the following tasks. Similar to ``packer`` but it is more simplified. 

1. Download iso image from remote site.
2. Run ``qemu`` with the .iso and FD image and boot installer from the .iso.
3. Send boot command to console then the unattended install is kicked.
   Configuration files for the installer are supplied from FD image.
4. Shutdown ``qemu`` from guest once all done.

## How to use

Basic usage:

```
% qemu-build build.conf
```

``build.conf`` has set of shell variables to build new OS image from iso installer.

```
target_image=centos7.img
kickstart_file="ks.cfg"
iso_checksum="d07ab3e615c66a8b2e9a50f4852e6a77"
iso_urls=(
  http://ftp.riken.jp/Linux/centos/7.1.1503/isos/x86_64/CentOS-7-x86_64-Minimal-1503-01.iso
)
# "<tab>text<space>ks=hd:fd0:/ks.cfg"
boot_commands=(tab t e x t spc k s equal h d shift-semicolon f d 0 shift-semicolon  slash k s dot c f g ret)
qemu_args="-m 1G"
post_scripts=(./post-scripts/*.sh)
```

```
# yum install -y $(qemu-build --show-deps)
```

## Config Parameters

Path information is calculated from the location of config file.

Required: 

``iso_checksum`` 

``iso_urls`` is shell array to supply the list of OS installer image file on remote site. It continues to 
try next urls until fetching succeeds.

``install_iso`` is path string to the installer image which you already have. ``iso_urls`` is skipped if this 
parameter is set.

``target_image`` the path to image file to generate.

Optional:

``kickstart_file`` the file is copied to FD image.

``boot_commands`` are sent to qemu guest over ``sendkey`` monitor interface while the OS installer prompts
and waits for typing keys. ``sendkey`` emulates keyboard so it can only pass one character at a time. See
the sendkey character list pasted from ``qemu``.

``qemu_args`` extra command options for ``qemu`` if you need.

``qemu_binary`` path to ``qemu`` binary.

``post_scripts`` an array of script path(s) to run at post stage in qemu guest. The files are just copied
to FD image. unattended installation must be organized to call them. 

``local_scripts`` an array of command line which run at qemu host. They are called after sending ``boot_commands``
so helps to handle post process on host side until the installation completes.


### Local Script

Bundled local scripts:

``screen-watch`` monitors qemu screen updates. It supports
to detect if updates happens within a period time and kill
qemu if the installation process is likely to be stopped.

``alt-b`` is just sends alt-b key sequence to qemu. It is
useful to signal CentOS graphical installer to proceed.


### ``sendkey`` character table


```
# discover the supported keys by doing:
#   telnet 127.0.0.1 4567
#   sendkey <tab>
# Here is the result:
(qemu) sendkey
0              1              2              3              4
5              6              7              8              9
a              again          alt            alt_r          altgr
altgr_r        apostrophe     asterisk       b              backslash
backspace      bracket_left   bracket_right  c              caps_lock
comma          compose        copy           ctrl           ctrl_r
cut            d              delete         dot            down
e              end            equal          esc            f
f1             f10            f11            f12            f2
f3             f4             f5             f6             f7
f8             f9             find           front          g
grave_accent   h              help           home           i
insert         j              k              kp_0           kp_1
kp_2           kp_3           kp_4           kp_5           kp_6
kp_7           kp_8           kp_9           kp_add         kp_decimal
kp_divide      kp_enter       kp_multiply    kp_subtract    l
left           less           lf             m              menu
meta_l         meta_r         minus          n              num_lock
o              open           p              paste          pause
pgdn           pgup           print          props          q
r              ret            right          s              scroll_lock
semicolon      shift          shift_r        slash          spc
stop           sysrq          t              tab            u
undo           unmapped       up             v              w
x              y              z
```
