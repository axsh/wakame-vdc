REM Splitting out error output to separate log because of PowerShell bug:
REM http://www.leeholmes.com/blog/2008/07/30/workaround-the-os-handles-position-is-not-what-filestream-expected/

PowerShell -ExecutionPolicy Unrestricted C:\Windows\Setup\Scripts\wakame-init-first-boot.ps1 >>"C:\Windows\Setup\Scripts\wakame.log.txt" 2>>"C:\Windows\Setup\Scripts\wakame.log.err"


