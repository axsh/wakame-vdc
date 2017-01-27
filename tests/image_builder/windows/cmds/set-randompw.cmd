@echo off
::-------------------------------------
::ランダムパスワードを発行し、パスワードを暗号化して保存
::-------------------------------------
set LOG_FILE=c:\wakame-init.log
set OPENSSL_PATH=%~dp0..\openssl-0.9.8k
set OPENSSL_CMD=%OPENSSL_PATH%\bin_32\openssl.exe
set CURL_PATH=%~dp0..\curl
set CURL_CMD=%CURL_PATH%\curl-7.27.0-ssl-sspi-zlib-static-bin-w32\curl.exe
if defined ProgramFiles(x86) (
	set OPENSSL_CMD=%OPENSSL_PATH%\bin_X64\openssl.exe
	set CURL_CMD=%CURL_PATH%\curl-7.23.1-win64-ssl-sspi\curl.exe
)
REM echo %OPENSSL_CMD%

set PW_PARSE_CMD=%~dp0GetPasswd.exe
set PWCHG_USER=Guest
REM set PWCHG_USER=Administrator
REM set PLAIN_FILE=%~dp0random.txt

::echo %date% %time% ^(I^)^:find-metadrv >> %LOG_FILE%
SET FIND_METADRV_CMD=%~dp0find-metadrv.cmd
for /f "usebackq tokens=*" %%i in (`%FIND_METADRV_CMD%`) do @set META_DRV=%%i
::echo %date% %time% ^(I^)^:find drive^:%META_DRV% >> %LOG_FILE%
if "%META_DRV%" == "" (
::META_DRVが見つからない場合は、強制終了
	echo %date% %time% ^(E^)^:METADRIVE not found. >> %LOG_FILE%
	exit /b 1
)

set PUBLIC_KEY_DIR=%META_DRV%:\meta-data\public-keys\0
set ENCODE_FILE=%PUBLIC_KEY_DIR%\%PWCHG_USER%.enc
set PUBLIC_PEM_FILE=%PUBLIC_KEY_DIR%\public-rsa.pem
set PRIVATE_PEM_FILE=%~dp0..\ssh-demo.pem

if "%1" == "-decrypt" (
::復号化テスト
	%OPENSSL_CMD% rsautl -inkey %PRIVATE_PEM_FILE% -in %ENCODE_FILE% -decrypt
	exit /b 0
)

if exist %ENCODE_FILE% (
::既に暗号化済みのファイルがあれば処理せずに終了
	echo %date% %time% ^(I^)^:encrypt file is already. >> %LOG_FILE%
	exit /b 0
)

if not exist %PUBLIC_PEM_FILE% (
::公開鍵が見つからない場合は処理せずに終了
	echo %date% %time% ^(I^)^:public pem file is not found. >> %LOG_FILE%
	exit /b 2
)

set PW_RANDOM_CMD=net user %PWCHG_USER% /random
set ENCRYPT_CMD=%OPENSSL_CMD% rsautl -pubin -inkey %PUBLIC_PEM_FILE% -encrypt -out %ENCODE_FILE%

%PW_RANDOM_CMD% | %PW_PARSE_CMD% | %ENCRYPT_CMD%
echo %date% %time% ^(I^)^:%PWCHG_USER% randam password success. >> %LOG_FILE%

set UPDPASSWD_CMD=%CURL_CMD% --location --upload-file %ENCODE_FILE% http://169.254.169.254/latest/meta-data/login/%PWCHG_USER%/encrypted-password
%UPDPASSWD_CMD%
echo %date% %time% ^(I^)^:%PWCHG_USER% password metaserver updated. >> %LOG_FILE%
