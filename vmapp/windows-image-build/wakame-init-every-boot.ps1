
"Starting wakame-init-every-boot.ps1" | Write-Host

. "C:\Windows\Setup\Scripts\wakame-functions.ps1"

# Set up networking
Get_Metadata_Mac_Addresses | foreach { Set_Networking_From_Metadata( $_ ) }
# The above can sometimes fail for multiple nics where one nic already has the
# intended setting as the nic the code is currently trying to set.  Windows
# seems to just ignore the request without throwing any errors.  The simple solution
# here is just to set everything twice.
Get_Metadata_Mac_Addresses | foreach { Set_Networking_From_Metadata( $_ ) }

Update_Hosts_File

Try_Auto_Activation

$mdl = Get_MD_Letter
if (Test-Path ("$mdl\meta-data\first-boot"))
{
    # Wakame is starting from an image that did not have sysprep
    # treatment.  Because Wakame expects images to behave as if
    # sysprep'ed, the password generation and shutdown are run here to
    # simulate the first-boot script.
    Generate_Password

    # Make sure this does not run again on the next boot
    Remove-Item "$mdl\meta-data\first-boot"
    
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
