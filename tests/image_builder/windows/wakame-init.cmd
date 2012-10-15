@echo off

set LOG_FILE=c:\wakame-init.log

echo %date% %time% ^(I^)^:start wakame-init.cmd >> %LOG_FILE%
::30•b‹^Ž—ƒXƒŠ[ƒv
::ping localhost -n 30 > nul

::-------------------------------------
::‡@list voume‚ÌŒ‹‰ÊVolume###,Ltr,Lablel`‚©‚ç3‚Â‚ß‚ðŽæ“¾AŒŸõðŒ‚ÍMETADRIVE
::-------------------------------------
echo %date% %time% ^(I^)^:find-metadrv >> %LOG_FILE%
SET FIND_METADRV_CMD=%~dp0cmds\find-metadrv.cmd
for /f "usebackq tokens=*" %%i in (`%FIND_METADRV_CMD%`) do @set META_DRV=%%i
echo %date% %time% ^(I^)^:find drive^:%META_DRV% >> %LOG_FILE%
if "%META_DRV%" == "" (
::META_DRV‚ªŒ©‚Â‚©‚ç‚È‚¢ê‡‚ÍA‹­§I—¹
	echo %date% %time% ^(E^)^:METADRIVE not found. >> %LOG_FILE%
	exit /b 1
)

set META_DATA_DIR=%META_DRV%:\meta-data

::-------------------------------------
::‡Alocal-ipv4ƒtƒ@ƒCƒ‹(‡@‚ÅŽæ“¾‚µ‚½)‚Ì’†g‚ÌipƒAƒhƒŒƒX‚ðŽæ“¾‚·‚é
::-------------------------------------
set IPV4_FILE=%META_DATA_DIR%\local-ipv4
if not exist %IPV4_FILE% (
	echo %date% %time% ^(E^)^: local-ipv4 file^(%IPV4_FILE%^) not found. >> %LOG_FILE%
	exit /b 2
)

for /f "usebackq tokens=*" %%a in (`type %IPV4_FILE%`) do set IP_V4=%%a
echo %date% %time% ^(I^)^:IPaddress^:%IP_V4% >> %LOG_FILE%

::-------------------------------------
::‡BmacƒAƒhƒŒƒXŽæ“¾
::-------------------------------------
set MAC_FILE=%META_DATA_DIR%\mac
if not exist %MAC_FILE% (
	echo %date% %time% ^(E^)^: mac file^(%MAC_FILE%^) not found. >> %LOG_FILE%
	exit /b 3
)

for /f "usebackq tokens=*" %%a in (`type %MAC_FILE%`) do set MAC=%%a
echo %date% %time% ^(I^)^:MACaddress^:%MAC% >> %LOG_FILE%

::-------------------------------------
::‡CmacƒAƒhƒŒƒX‚©‚çInterfacenameŽæ“¾
::-------------------------------------
set MAC_ADDR=%MAC::=-%
echo %date% %time% ^(I^)^:MACaddress^:%MAC_ADDR% >> %LOG_FILE%
set GET_IFNAME=%~dp0cmds\GetNetConfig.exe -mac %MAC_ADDR% -print ifname -notitle
for /f "usebackq tokens=*" %%a in (`%GET_IFNAME%`) do set IF_NAME=%%a
if "%IF_NAME%" == "" (
	echo %date% %time% ^(E^)^: Interface Name^(%MAC_ADDR%^) not found. >> %LOG_FILE%
	exit /b 4
)
echo %date% %time% ^(I^)^:Interface Name^:%IF_NAME% >> %LOG_FILE%

set META_NETWORK_DIR=%META_DATA_DIR%\network\interfaces\macs\%MAC_ADDR%
::-------------------------------------
::‡DgatewayŽæ“¾
::-------------------------------------
set GATEWAY_FILE=%META_NETWORK_DIR%\x-gateway
if not exist %GATEWAY_FILE% (
	echo %date% %time% ^(E^)^: gateway file^(%GATEWAY_FILE%^) not found. >> %LOG_FILE%
	exit /b 5
)

for /f "usebackq tokens=*" %%a in (`type %GATEWAY_FILE%`) do set IP_GW=%%a
echo %date% %time% ^(I^)^:Gateway^:%IP_GW% >> %LOG_FILE%

::-------------------------------------
::‡EmaskŽæ“¾
::-------------------------------------
set NETMASK_FILE=%META_NETWORK_DIR%\x-netmask
if not exist %NETMASK_FILE% (
	echo %date% %time% ^(E^)^: netmask file^(%NETMASK_FILE%^) not found. >> %LOG_FILE%
	exit /b 6
)

for /f "usebackq tokens=*" %%a in (`type %NETMASK_FILE%`) do set IP_MASK=%%a
echo %date% %time% ^(I^)^:Mask^:%IP_MASK% >> %LOG_FILE%

::-------------------------------------
::‡FdnsŽæ“¾
::-------------------------------------
set DNS_FILE=%META_NETWORK_DIR%\x-dns
if not exist %DNS_FILE% (
	echo %date% %time% ^(E^)^: dns file^(%DNS_FILE%^) not found. >> %LOG_FILE%
	exit /b 7
)

for /f "usebackq tokens=*" %%a in (`type %DNS_FILE%`) do set IP_DNS=%%a
echo %date% %time% ^(I^)^:DNS^:%IP_DNS% >> %LOG_FILE%

::-------------------------------------
::‡Gip/mask/gatewayƒZƒbƒg
::-------------------------------------
set GET_IFNAME_CHECK=%~dp0cmds\GetNetConfig.exe -ipv4 %IP_V4% -mask %IP_MASK% -gw %IP_GW% -mac %MAC_ADDR% -print ifname -notitle
for /f "usebackq tokens=*" %%a in (`%GET_IFNAME_CHECK%`) do set IF_NAME_CHECK=%%a

if not "%IF_NAME%" == "%IF_NAME_CHECK%" (
	echo %date% %time% ^(I^)^:netsh interface ipv4 set address name="%IF_NAME%" source=static address=%IP_V4% mask=%IP_MASK% gateway=%IP_GW%  >> %LOG_FILE%
	netsh interface ipv4 set address name="%IF_NAME%" source=static address=%IP_V4% mask=%IP_MASK% gateway=%IP_GW%
)

::DNS‚ÌÝ’è‚ðs‚¤
::set IP_DNS=
::if not "%IP_DNS%" == "" (
echo %date% %time% ^(I^)^:netsh interface ipv4 set dnsserver "%IF_NAME%" static %IP_DNS% primary  >> %LOG_FILE%
netsh interface ipv4 set dnsserver "%IF_NAME%" static %IP_DNS% primary
::)

::secondary dns
::netsh interface ipv4 add dnsserver name="%IF_NAME%" address=%IP_DNS% index=2

::-------------------------------------
::‡HARPiAddress Resolution Protocoljƒe[ƒuƒ‹
::-------------------------------------
echo %date% %time% ^(I^)^:arp -s 169.254.169.254 %MAC_ADDR%   >> %LOG_FILE%
arp -s 169.254.169.254 %MAC_ADDR%

::-------------------------------------
::‡Ihost–¼ƒZƒbƒg
::-------------------------------------
set HOSTNAME_FILE=%META_DATA_DIR%\local-hostname
if not exist %HOSTNAME_FILE% (
	echo %date% %time% ^(E^)^: host file^(%HOSTNAME_FILE%^) not found. >> %LOG_FILE%
	exit /b 9
)

for /f "usebackq tokens=*" %%a in (`type %HOSTNAME_FILE%`) do set RENAME_HOST=%%a

::¬•¶Žš‚ð‘å•¶Žš‚É•ÏŠ·
for %%I in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) ^
do call set RENAME_HOST=%%RENAME_HOST:%%I=%%I%%

echo %date% %time% ^(I^)^:HostName^:%COMPUTERNAME%-^>%RENAME_HOST% >> %LOG_FILE%

if not "%COMPUTERNAME%" == "%RENAME_HOST%" (
	echo %date% %time% ^(D^)^:wmic ComputerSystem where Name="%COMPUTERNAME%" call Rename Name="%RENAME_HOST%" >> %LOG_FILE%
	wmic ComputerSystem where Name="%COMPUTERNAME%" call Rename Name="%RENAME_HOST%"
	::Ä‹N“®‚µ‚È‚¢‚Æ”½‰f‚³‚ê‚È‚¢
	::netdom renamecomputer %computername% /newname:%hostname%
	echo %date% %time% ^(I^)^:shutdown restart >> %LOG_FILE%
	shutdown /r /t 0
	exit /b 0
)

::-------------------------------------
::‡Jset-randompw.cmdŒÄ‚Ño‚µ
::-------------------------------------
SET RANDOM_PASSWD_CMD=%~dp0cmds\set-randompw.cmd
echo %date% %time% ^(I^)^:set-randompw >> %LOG_FILE%
for /f "usebackq tokens=*" %%i in (`%RANDOM_PASSWD_CMD%`) do @set RANDOM_PASS=%%i

echo %date% %time% ^(I^)^:end wakame-init.cmd >> %LOG_FILE%
