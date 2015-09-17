REM Be aware of the following in case writing to stdout causes errors:
REM http://www.leeholmes.com/blog/2008/07/30/workaround-the-os-handles-position-is-not-what-filestream-expected/

PowerShell -ExecutionPolicy Unrestricted C:\Windows\Setup\Scripts\wakame-init-every-boot.ps1 2>&1 >>"C:\Windows\Setup\Scripts\wakame-every-boot.log"
