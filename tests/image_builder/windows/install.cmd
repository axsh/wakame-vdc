@echo off
:: in Guest Machine
:: > mkdir \share
:: > net share sharename=C:\share /grant:everyone,full
::
:: in Host Machine
:: copy vm@sharename windows folder 
:: in Guest Machine
::
:: > c:\share\install.cmd

:: Remote Desktop Enable
::cscript %windir%\system32\scregedit.wsf /ar 0

:: ICMP Enable
::netsh firewall set icmpsetting 8

:: wakame-init.cmd Startup
::xcopy /e /h /f autoscript %windir%\system32\GroupPolicy

:: Group policy Update
::gpupdate

::install VC2010 x86 runtime
::vc2010runtime\vcredist_x86.exe

::sysprep settings
::copy windows-ESC-x86.xml %windir%\system32\sysprep\
::%windir%\system32\sysprep\sysprep /generalize /oobe /shutdown /unattend:windows-ESC-x86.xml

::ping or rpc(dns activate)
::delete dns
::netsh interface ipv4 delete dnsserver name="ローカル エリア接続" all
::set dns
::netsh interface ipv4 set dnsserver name="ローカル エリア接続" static 8.8.8.8 primary
::time server sync
::w32tm /resync
