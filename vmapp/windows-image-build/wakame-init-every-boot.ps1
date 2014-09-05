
"Starting wakame-init-every-boot.ps1" | Write-Host

. "C:\Windows\Setup\Scripts\wakame-functions.ps1"

# Set up networking
Get_Metadata_Mac_Addresses | foreach { Set_Networking_From_Metadata( $_ ) }
# The above can sometimes fail for multiple nics where one nic already has the
# intended setting as the nic the code is currently trying to set.  Windows
# seems to just ignore the request without throwing any errors.  The simple solution
# here is just to set everything twice.
Get_Metadata_Mac_Addresses | foreach { Set_Networking_From_Metadata( $_ ) }

try {
    # Update hosts file
    $hpath = "C:\Windows\System32\drivers\etc\hosts"
    $comment="# Please do not modify lines from here by your hand since wakame-init will place entries from metadata."
    try {
	$oldlines = [System.IO.File]::ReadAllLines($hpath)
        $null | Out-File $hpath -Encoding utf8
	foreach ( $ln in $oldlines ) {
	    if ($ln -match "do not modify") { break }
            $ln | Out-File $hpath -Encoding utf8 -Append
	}
    }
    catch {
	$Error[0] | Write-Host
	Write-Host "Creating new hosts file"
        $null | Out-File $hpath -Encoding utf8
    }
    $comment | Out-File $hpath -Encoding utf8 -Append
    $mdl = Get_MD_Letter
    (Get-ChildItem "$mdl\meta-data\extra-hosts") | foreach {
	$hostname = $_
        $hostip = [System.IO.File]::ReadAllText("$mdl\meta-data\extra-hosts\$hostname").trim()
	"${hostip} ${hostname}" | Out-File $hpath -Encoding utf8 -Append
    }
}
catch {
    $Error[0] | Write-Host
    Write-Host "Error occurred while updating hosts file"
}

if (Test-Path ("$mdl\meta-data\auto-activate"))
{
    try {
	$proxy = ""
	if (Test-Path ("$mdl\meta-data\auto-activate-proxy")) {
	    $proxy = Read_Metadata("auto-activate-proxy")
	    Write-Host "Setting proxy to $proxy."
	    netsh.exe winhttp set proxy $proxy 2>&1 | Write-Host
	}
	netsh.exe winhttp show proxy 2>&1 | Write-Host
	Write-Host "Trying auto activation"
	cscript.exe //b c:\windows\system32\slmgr.vbs /ato 2>&1 | Write-Host
	if ($proxy -ne "") {
	    netsh.exe winhttp reset proxy 2>&1 | Write-Host
	}
    }
    catch {
	$Error[0] | Write-Host
	Write-Host "Error occurred during auto activation"
    }
}

if (Test-Path ("$mdl\meta-data\first-boot"))
{
    # A zero byte pw.enc file will indicate to HVA that the image (now
    # going through first boot) had not been prepared with sysprep.
    try {
	[System.IO.File]::WriteAllBytes("$mdl\meta-data\pw.enc",@())
    }
    catch {
	$Error[0] | Write-Host
	Write-Host "Error occurred while writing out empty pw.enc file"
    }

    # shutdown
    Stop-Computer
}

try {
    $confpath="C:\Program Files\ZABBIX Agent\zabbix_agentd.conf"
    $exepath="C:\Program Files\ZABBIX Agent\zabbix_agentd.exe"

    # turn off zabbix
    & $exepath -c $confpath --stop 2>&1 | Write-Host

    $hostname = Read_Metadata("instance-id")
    $listenIP = Read_Metadata("local-ipv4")
    $server = Read_Metadata("x-monitoring/zabbix-servers")
    $server = $server -replace " ", ","

    # change configuration files
    $oldlines = [System.IO.File]::ReadAllLines($confpath)
    $oldlines = $oldlines | % { $_ -replace "^Hostname=.*", "Hostname=$hostname" }
    # (Next line exists because Windows installer initially comments out ListenIP parameter)
    $oldlines = $oldlines | % { $_ -replace "^# ListenIP=127.0.0.1.*", "ListenIP=127.0.0.1" }
    $oldlines = $oldlines | % { $_ -replace "^ListenIP=.*", "ListenIP=$listenIP" }
    $oldlines = $oldlines | % { $_ -replace "^Server=.*", "Server=$server" }
    # zabbix seems OK w/ UTF8, which the next line writes to disk
    [System.IO.File]::WriteAllLines($confpath, $oldlines)


    # turn zabbix back on
    & $exepath -c $confpath --start 2>&1 | Write-Host
}
catch {
    $Error[0] | Write-Host
    Write-Host "Error occurred while configuring Zabbix"
}

"Finishing wakame-init-every-boot.ps1" | Write-Host
