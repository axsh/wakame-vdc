
mkdir c:\Windows\Setup\Scripts\

REM INSTALL PHASE
REM (Answer file is read directly from floppy drive a:)
REM Name this SetupComplete.cmd so it runs after install phase finishes
copy a:\SetupComplete-install.cmd c:\Windows\Setup\Scripts\SetupComplete.cmd

REM FIRST BOOT PHASE
REM a:run-sysprep.cmd will point sysprep to this answer file
copy a:\Unattend-for-first-boot.xml c:\Windows\Setup\Scripts\
REM a:run-sysprep.cmd will rename this to SetupComplete.cmd so it runs after first boot
copy a:\SetupComplete-firstboot.cmd c:\Windows\Setup\Scripts\
REM the renamed SetupComplete-firstboot.cmd will run this
copy a:\wakame-init-first-boot.ps1 c:\Windows\Setup\Scripts\
REM wakame-init-first-boot.ps1 will read this key and overwrite file
copy a:\keyfile c:\Windows\Setup\Scripts\

REM EVERY BOOT PHASE
REM wakame-init-first-boot.ps1 installs these with schtasks.exe
copy a:\wakame-init-every-boot.cmd c:\Windows\Setup\Scripts\
copy a:\wakame-init-every-boot.ps1 c:\Windows\Setup\Scripts\

REM Sysprep Helper Script for User
copy a:\sysprep-for-backup.cmd c:\Windows\Setup\Scripts\

REM used by the a:\wakame-init-*-boot.ps1 scripts
copy a:\wakame-functions.ps1 c:\Windows\Setup\Scripts\
