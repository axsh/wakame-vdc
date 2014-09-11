
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
    # Generate password
    Add-Type -AssemblyName System.Web
    $randpass = [System.Web.Security.Membership]::GeneratePassword(10,2).ToCharArray()
    $Encode = New-Object "System.Text.UTF8Encoding"
    $randpasstxt = $Encode.GetString([byte[]] $randpass)

    # Encrypt password
    $MetaSshpub = Read_Metadata("public-keys\0\openssh-key")
    $XmlPublicKey =  sshpubkey2xml( $MetaSshpub )
    $rsaProvider = New-Object System.Security.Cryptography.RSACryptoServiceProvider
    $rsaProvider.FromXmlString($XmlPublicKey.InnerXml)
    $ee = $rsaProvider.Encrypt($randpass,$true)
    $mdl = Get_MD_Letter
    [System.IO.File]::WriteAllBytes("$mdl\meta-data\pw.enc",$ee)

    # Change Administrator password
    $computer=hostname
    $username="Administrator"
    $user = [adsi]"WinNT://$computer/$username,user"
    $user.SetPassword($randpasstxt)
    $user.SetInfo()
}
catch {
    $Error[0] | Write-Host
    Write-Host "Error occurred while setting Administrator password"
}

try {
    # Turn on RDP
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 0

    # All external commands are piped through Write-Host so they do
    # not access stdout and stderr directly, which avoids a bug in
    # PowerShell in Windows Server 2008.
    # see: http://www.leeholmes.com/blog/2008/07/30/workaround-the-os-handles-position-is-not-what-filestream-expected/
    netsh.exe advfirewall set currentprofile state off 2>&1 | Write-Host  # completely turn off firewall
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

Update_Hosts_File

Try_Auto_Activation

"Finishing wakame-init-first-boot.ps1...about to do Stop-Computer" | Write-Host

# shutdown
Stop-Computer
