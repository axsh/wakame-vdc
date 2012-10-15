@echo off

::-------------------------------------
::‡@list voume‚ÌŒ‹‰ÊVolume###,Ltr,Lablel`‚©‚ç3‚Â‚ß‚ðŽæ“¾AŒŸõðŒ‚ÍMETADATA
::-------------------------------------
for /f "tokens=3" %%i in ('echo list volume ^| diskpart ^| find "METADATA"') do set META_DRV=%%i

if not "%META_DRV%" == "METADATA" (

	echo.%META_DRV%
	exit /b 0

)

set META_DRV=X
for /f "tokens=2" %%i in ('echo list volume ^| diskpart ^| find "METADATA"') do set DISKVOL=%%i

set SCRIPT_FILE=%~dp0diskpart.txt
echo select volume %DISKVOL% > %SCRIPT_FILE%
echo assign letter=%META_DRV% >> %SCRIPT_FILE%
diskpart /s %SCRIPT_FILE% > NUL
del %SCRIPT_FILE%
echo.%META_DRV%



