## Example Build Log

```bash
$ ./build-dir-utils.sh builddirs/manual-build-2008/ 0-init 2008
Starting build-dir-utils.sh (0-init)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=2008
    ./nextstep=
Finished build-dir-utils.sh (0-init), ./nextstep is now 1-setup-install



$ export ISO2008=7601.17514.101119-1850_x64fre_server_eval_ja-jp-GRMSXEVAL_JA_DVD.iso
$ export KEY2008=none
$ ./build-dir-utils.sh builddirs/manual-build-2008/ 1-setup-install
Starting build-dir-utils.sh (1-setup-install)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=1-setup-install

Install parameters were written to:
  /media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008/install-params
Installed: virtio-win-0.1-74.iso
Installed: zabbix_agent-1.8.15-1.JP_installer.exe
Installed: 7601.17514.101119-1850_x64fre_server_eval_ja-jp-GRMSXEVAL_JA_DVD.iso
All required resources were found.
Finished build-dir-utils.sh (1-setup-install), ./nextstep is now 2-create-floppy-image-with-answer-file

Everything should be ready.  Invoke with -do-next to create the floppy image used for Windows installation.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -do-next
Starting build-dir-utils.sh (-do-next)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=2-create-floppy-image-with-answer-file
1440+0 records in
1440+0 records out
1474560 bytes (1.5 MB) copied, 0.0063741 s, 231 MB/s
mkfs.fat 3.0.27 (2014-11-12)
Finished build-dir-utils.sh (-do-next), ./nextstep is now 3-boot-with-install-iso-and-floppy

Floppy image created.  Invoke again with -do-next to boot KVM with the Windows installation ISO.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -do-next
Starting build-dir-utils.sh (-do-next)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=3-boot-with-install-iso-and-floppy
Formatting 'win-2008.raw', fmt=raw size=32212254720
Finished build-dir-utils.sh (-do-next), ./nextstep is now 4-M-wait-for-ctrl-alt-delete-screen

The Windows install ISO should be booting and installing Windows.  The
next step is to confirm that installation was successful, KVM rebooted,
and the 'Ctrl + Alt + Del' screen appeared.  If the 'Answerfile' on
the floppy worked correctly, this should all happen automatically, in
which case all that is necessary is to wait 5 or 10 minutes and verify
that the 'Ctrl + Alt + Del' screen appeared.  If not, it may be
possible to respond to installation dialog boxes to get the
installation to complete.  In either case, view KVM console by doing
'vncviewer :6080'.  When 'Ctrl + Alt + Del' appears,
invoke this script again using the -done parameter to confirm that
this step is done. (Do not log in yet)

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=4-M-wait-for-ctrl-alt-delete-screen
Finished build-dir-utils.sh (-done), ./nextstep is now 5-record-logs-at-ctrl-alt-delete-screen

Invoke again with -do-next to record logs from the new Windows image.
(Do not log in yet)

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -do-next
Starting build-dir-utils.sh (-do-next)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=5-record-logs-at-ctrl-alt-delete-screen
Making tar file of log files from Windows image --> ./logs-001-at-ctrl-alt-delete-screen.tar.gz
(Error messages for "No such file..." are normal)
tar: Windows/WindowsUpdate.log: Cannot stat: No such file or directory
tar: Program Files/ZABBIX Agent/zabbix_agentd.conf: Cannot stat: No such file or directory
tar: Exiting with failure status due to previous errors
Unmounting: mntpoint
Detaching: /dev/loop0
Finished build-dir-utils.sh (-do-next), ./nextstep is now 6-M-press-ctrl-alt-delete-screen

Next, press ctrl-alt-delete, then invoke again with -done.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=6-M-press-ctrl-alt-delete-screen
Finished build-dir-utils.sh (-done), ./nextstep is now 7-M-wait-for-password-screen

Wait for password screen to appear, then invoke this script again with -done.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=7-M-wait-for-password-screen
Finished build-dir-utils.sh (-done), ./nextstep is now 8-M-enter-password

Enter 'a:run-sysprep' as the password. then invoke this script again with -done.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=8-M-enter-password
Finished build-dir-utils.sh (-done), ./nextstep is now 9-M-wait-for-login-completion

Wait for login to complete, then invoke this script again with -done.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=9-M-wait-for-login-completion
Finished build-dir-utils.sh (-done), ./nextstep is now 10-M-open-powershell-window

Click on the PowerShell icon.  Make sure the PowerShell windows is in the
foreground, then invoke this script again with -done.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=10-M-open-powershell-window
Finished build-dir-utils.sh (-done), ./nextstep is now 11-M-run-sysprep-script

Type 'a:run-sysprep' in the PowerShell window and press return.
Then invoke this script again with -done.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=11-M-run-sysprep-script
Finished build-dir-utils.sh (-done), ./nextstep is now 12-M-wait-zabbix-installer-screen1

Wait for Zabbix installer to appear, then invoke this script again with -done.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=12-M-wait-zabbix-installer-screen1
Finished build-dir-utils.sh (-done), ./nextstep is now 13-M-press-return-1

Press return to select the 'next' button, then invoke this script again with -done.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=13-M-press-return-1
Finished build-dir-utils.sh (-done), ./nextstep is now 14-M-wait-zabbix-installer-screen2

Wait for the Zabbix license screen to appear, then invoke this script again with -done.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=14-M-wait-zabbix-installer-screen2
Finished build-dir-utils.sh (-done), ./nextstep is now 15-M-press-return-2

Press return to select the 'accept' button, then invoke this script again with -done.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=15-M-press-return-2
Finished build-dir-utils.sh (-done), ./nextstep is now 16-M-wait-zabbix-installer-screen3

Wait for the component Zabbix screen to appear, then invoke this script again with -done.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=16-M-wait-zabbix-installer-screen3
Finished build-dir-utils.sh (-done), ./nextstep is now 17-M-press-return-3

Press return to select the 'next' button, then invoke this script again with -done.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=17-M-press-return-3
Finished build-dir-utils.sh (-done), ./nextstep is now 18-M-wait-zabbix-installer-screen4

Wait for the configuration Zabbix screen to appear, then invoke this script again with -done.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=18-M-wait-zabbix-installer-screen4
Finished build-dir-utils.sh (-done), ./nextstep is now 19-M-press-return-4

Press return to select the 'next' button, then invoke this script again with -done.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=19-M-press-return-4
Finished build-dir-utils.sh (-done), ./nextstep is now 20-M-wait-zabbix-installer-screen5

Wait for the install folder Zabbix screen to appear, then invoke this script again with -done.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=20-M-wait-zabbix-installer-screen5
Finished build-dir-utils.sh (-done), ./nextstep is now 21-M-press-return-5

Press return to select the 'install' button, then invoke this script again with -done.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=21-M-press-return-5
Finished build-dir-utils.sh (-done), ./nextstep is now 22-M-wait-zabbix-installer-screen6

Wait for the install finished screen to appear, then invoke this script again with -done.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=22-M-wait-zabbix-installer-screen6
Finished build-dir-utils.sh (-done), ./nextstep is now 23-M-press-return-6

Press return to select the 'close' button, then invoke this script again with -done.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -done
Starting build-dir-utils.sh (-done)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=23-M-press-return-6
Finished build-dir-utils.sh (-done), ./nextstep is now 24-wait-for-shutdown

The Zabbix install should soon finish and the sysprep process should start
automatically.  Invoke this script again to have the script wait for sysprep
to finish and Windows to automatically shutdown.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -do-next
Starting build-dir-utils.sh (-do-next)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=24-wait-for-shutdown
Waited 0 seconds for KVM process to exit, will check again in 10 seconds.
Waited 10 seconds for KVM process to exit, will check again in 10 seconds.
Waited 20 seconds for KVM process to exit, will check again in 10 seconds.
Waited 30 seconds for KVM process to exit, will check again in 10 seconds.
Finished build-dir-utils.sh (-do-next), ./nextstep is now 25-record-logs-after-sysprep

Windows finished shutting down.
Invoke again with -do-next to record logs from the new sysprepped Windows image.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -do-next
Starting build-dir-utils.sh (-do-next)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=25-record-logs-after-sysprep
Making tar file of log files from Windows image --> ./logs-002-after-sysprep.tar.gz
(Error messages for "No such file..." are normal)
Unmounting: mntpoint
Detaching: /dev/loop0
Finished build-dir-utils.sh (-do-next), ./nextstep is now 26-make-simple-tar-of-image

Invoke again with -do-next to make a simple tar.gz archive of the new sysprepped Windows image.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -do-next
Starting build-dir-utils.sh (-do-next)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=26-make-simple-tar-of-image
+ md5sum win-2008.raw

real	1m45.161s
user	1m13.714s
sys	0m11.839s
++ cat ./timestamp
+ tar czSvf windows-2008-151009-194443.tar.gz win-2008.raw win-2008.raw.md5
win-2008.raw
win-2008.raw.md5

real	8m1.595s
user	6m57.530s
sys	0m43.799s
Finished build-dir-utils.sh (-do-next), ./nextstep is now 27-package-to-wakame-tgz-image

Invoke again with -do-next to make package into a Wakame-vdc tar.gz image.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -do-next
Starting build-dir-utils.sh (-do-next)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=27-package-to-wakame-tgz-image
win-2008.raw
win-2008.raw.md5

real	1m9.435s
user	1m6.864s
sys	0m29.333s
Detaching: /dev/loop0
+ evalcheck 'tar czvSf "$seedtar" "${seedtar%.tar.gz}"'
+ eval 'tar czvSf "$seedtar" "${seedtar%.tar.gz}"'
++ tar czvSf windows2008r2.x86_64.kvm.md.raw.tar.gz windows2008r2.x86_64.kvm.md.raw
windows2008r2.x86_64.kvm.md.raw

real	7m23.025s
user	6m56.539s
sys	0m39.684s
+ evalcheck 'md5sum "$seedtar" >"$seedtar".md5'
+ eval 'md5sum "$seedtar" >"$seedtar".md5'
++ md5sum windows2008r2.x86_64.kvm.md.raw.tar.gz

real	0m6.597s
user	0m6.124s
sys	0m0.459s
+ output-image-install-script windows2008r2.x86_64.kvm.md.raw.tar.gz
+ seedtar=windows2008r2.x86_64.kvm.md.raw.tar.gz
++ head -c 32 windows2008r2.x86_64.kvm.md.raw.tar.gz.md5
+ md5=5848430c05d50876cb329992bcba0918
+ cat
++ file-size windows2008r2.x86_64.kvm.md.raw.tar.gz
+++ ls -l windows2008r2.x86_64.kvm.md.raw.tar.gz
++ lsout='-rw-r--r-- 1 triggers triggers 3051425536 Oct  9 20:44 windows2008r2.x86_64.kvm.md.raw.tar.gz'
++ read t1 t2 t3 t4 fsize rest
++ echo 3051425536
Finished build-dir-utils.sh (-do-next), ./nextstep is now 28-package-to-wakame-qcow2-image

Invoke again with -do-next to make package into a Wakame-vdc qcow2 image.

$ ./build-dir-utils.sh builddirs/manual-build-2008/ -do-next
Starting build-dir-utils.sh (-do-next)
    bdir_fullpath=/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008
    ${params[@]}=
    ./nextstep=28-package-to-wakame-qcow2-image
/media/sdc1/potter-backup/dev/wakame-july2015-windows-fixes/t1/wakame-vdc/vmapp/windows-image-build/builddirs/manual-build-2008/final-seed-image
+ '[' -f windows2008r2.x86_64.kvm.md.raw ']'
+ evalcheck qemu-img convert -f raw -O qcow2 windows2008r2.x86_64.kvm.md.raw windows2008r2.x86_64.15071.qcow2
+ eval qemu-img convert -f raw -O qcow2 windows2008r2.x86_64.kvm.md.raw windows2008r2.x86_64.15071.qcow2
++ qemu-img convert -f raw -O qcow2 windows2008r2.x86_64.kvm.md.raw windows2008r2.x86_64.15071.qcow2
+ evalcheck md5sum windows2008r2.x86_64.15071.qcow2
+ eval md5sum windows2008r2.x86_64.15071.qcow2
++ md5sum windows2008r2.x86_64.15071.qcow2
+ evalcheck gzip windows2008r2.x86_64.15071.qcow2
+ eval gzip windows2008r2.x86_64.15071.qcow2
++ gzip windows2008r2.x86_64.15071.qcow2
+ evalcheck md5sum windows2008r2.x86_64.15071.qcow2.gz
+ eval md5sum windows2008r2.x86_64.15071.qcow2.gz
++ md5sum windows2008r2.x86_64.15071.qcow2.gz
Finished build-dir-utils.sh (-do-next), ./nextstep is now 1001-gen0-first-boot

Image building and packaging is now complete.

If desired, invoke again with -do-next to do a 'first-boot' test of the image.

$
```
