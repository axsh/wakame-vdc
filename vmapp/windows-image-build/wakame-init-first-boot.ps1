
"Starting wakame-init-first-boot.ps1" | Write-Host

. "C:\Windows\Setup\Scripts\wakame-functions.ps1"

# Set up networking
Get_Metadata_Mac_Addresses | foreach { Set_Networking_From_Metadata( $_ ) }
# The above can sometimes fail for multiple nics where one nic already has the
# intended setting as the nic the code is currently trying to set.  Windows
# seems to just ignore the request without throwing any errors.  The simple solution
# here is just to set everything twice.
Get_Metadata_Mac_Addresses | foreach { Set_Networking_From_Metadata( $_ ) }

try {
    # If the bootstatuspolicy is not changed, it is possible for Windows Server,
    # especially 2008, to boot to safe mode.  If the user does not have access
    # to the (VNC) console, the instance can become essentially stuck in safe mode and
    # never boot far enough for connecting through RDP.
    Write-host "bededit (before):"
    bcdedit  2>&1 | Write-Host
    bcdedit /set bootstatuspolicy ignoreallfailures 2>&1 | Write-Host
    Write-host "bededit (after):"
    bcdedit 2>&1 | Write-Host
}
catch {
    $Error[0] | Write-Host
    Write-Host "Error occurred while doing bcdedit /set bootstatuspolicy ignoreallfailures"
}

try {
    # Set hostname/computer name
    $metaHost = Read_Metadata("local-hostname")
    $computerName = Get-WmiObject Win32_ComputerSystem
    $computername.Rename($metahost)
}
catch {
    $Error[0] | Write-Host
    Write-Host "Error occurred while setting computer name"
}

try {
    # Turn on RDP
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 0

    # All external commands are piped through Write-Host so they do
    # not access stdout and stderr directly, which avoids a bug in
    # PowerShell in Windows Server 2008.
    # see: http://www.leeholmes.com/blog/2008/07/30/workaround-the-os-handles-position-is-not-what-filestream-expected/
    netsh.exe advfirewall firewall add rule name="Open Zabbix agentd port 10050 inbound" dir=in action=allow protocol=TCP localport=10050 2>&1 | Write-Host
    netsh.exe advfirewall firewall add rule name="Open Zabbix trapper port 10051 inbound" dir=in action=allow protocol=TCP localport=10051 2>&1 | Write-Host
    
    netsh.exe advfirewall firewall add rule name="Open Zabbix agentd port 10050 outbound" dir=out action=allow protocol=TCP localport=10050 2>&1 | Write-Host
    netsh.exe advfirewall firewall add rule name="Open Zabbix trapper port 10051 outbound" dir=out action=allow protocol=TCP localport=10051 2>&1 | Write-Host

    netsh.exe advfirewall firewall set rule group="remote desktop" new enable=Yes
}
catch {
    $Error[0] | Write-Host
    Write-Host "Error occurred while turning on RDP"
}

try {
    # Set up script for configuration on each reboot
    $onbootScript = "C:\Windows\Setup\Scripts\wakame-init-every-boot.cmd"
    # /f is required on next line, otherwise schtasks will prompt to overwrite existing task
    # See above comment about external commands.
    schtasks.exe /create /tn "Wakame Init" /tr "$onbootScript" /sc onstart /ru System /f 2>&1 | Write-Host
}
catch {
    $Error[0] | Write-Host
    Write-Host "Error occurred while setting up script for configuration on each reboot"
}

Generate_Password

Update_Hosts_File

Try_Auto_Activation

"Finishing wakame-init-first-boot.ps1...about to do Stop-Computer" | Write-Host

# shutdown
Stop-Computer
