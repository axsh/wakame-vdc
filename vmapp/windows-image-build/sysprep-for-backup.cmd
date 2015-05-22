
schtasks /delete /tn "Wakame Init" /f

del c:\Windows\Setup\Scripts\SetupComplete.cmd
copy c:\Windows\Setup\Scripts\SetupComplete-firstboot.cmd c:\Windows\Setup\Scripts\SetupComplete.cmd

cd c:\Windows\System32\sysprep
sysprep /oobe /generalize /shutdown /unattend:c:\Windows\Setup\Scripts\Unattend-for-first-boot.xml
