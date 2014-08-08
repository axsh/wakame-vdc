
"Starting wakame-init-first-boot.ps1" | Write-Host

function sshkeyfield( $barray, $index )
{
    $len = $barray[ $index + 3 ] + ( 256 * $barray[ $index + 2 ] )
    $start = $index + 4
    $end = $start + $len - 1
    ( $len, $start, $end )
}

function sshpubkey2xml( $sshkeystr )
{
    $base64part = $MetaSshpub.split(' ')[1]
    $keydata = [System.Convert]::FromBase64String($base64part)
    
    $lengthAll = $keydata.length
    $fp1 = sshkeyfield $keydata 0
    $fp2 = sshkeyfield $keydata ($fp1[2] + 1)
    $fp3 = sshkeyfield $keydata ($fp2[2] + 1)
    
    if ($lengthAll -ne ($fp3[2]+1)) {
	throw "Length fields inside ssh key do not add up correctly."
    }
    $Encode = new-object "System.Text.UTF8Encoding"
    $f1info = $keydata[ $fp1[1]..$fp1[2] ]
    $f1text = $Encode.GetString([byte[]] $f1info)
    if ($f1text -ne "ssh-rsa") {
	throw "Ssh key does not start with 'ssh-rsa'"
    }
    
    $f2info = $keydata[ $fp2[1]..$fp2[2] ]
    $f3info = $keydata[ (1 + $fp3[1])..$fp3[2] ]
    
    # Why does it start working when adding one here? (1 + $fp3[1]) This
    # was just a guess because the ssh-keygen modulus seems to be 0 0 1 1
    # = 257 in lengh, and produces a 257 byte encoded file.  But all the
    # other experiments with openssh and RSACryptoServiceProvider.Encrypt
    # produce 256 byte encoded files.  So I guessed and dropped the first
    # byte of the modulus, which was 0.
    
    $exponent64 = [System.Convert]::ToBase64String($f2info)
    $modulus64 = [System.Convert]::ToBase64String($f3info)
    
    [xml] "<RSAKeyValue><Modulus>$modulus64</Modulus><Exponent>$exponent64</Exponent></RSAKeyValue>"
}

$script:MDLetter = ""

function Get_MD_Letter()
{
    if ( $script:MDLetter -eq "" )
    {
	# Output initial disk status for debugging online/offline status
	"Testing 111" | Write-Host
	"list disk" | diskpart.exe 2>&1 | Write-Host
	"Testing 222" | Write-Host
	$vers = $PSVersionTable.PSVersion.Major
	"PowerShell Version: $($vers)" | Write-Host
	if ($vers -gt 2) {
	    # Get-Disk is not defined for version 2 PowerShell, so
	    # this will not work for Windows Server 2008. However, it
	    # seems to be unnecessary because the metadata disk is
	    # online by default.  It is needed to bring disks on
	    # Windows Server 2012 online.
	    "Bringing all disks online" | Write-Host
	    Get-Disk | ? IsOffline | Set-Disk -IsOffline:$false  # make sure all disks are online
	}
        $metavol = Get-WmiObject -class win32_volume -filter "Label = 'METADATA'"
	$script:MDLetter = $metavol.DriveLetter
	if ($script:MDLetter -eq $null)
	{
	    # set first free drive letter found with code from:
	    # http://stackoverflow.com/questions/12488030/getting-a-free-drive-letter
	    $script:MDLetter = (ls function:[e-z]: -n | ?{ !(test-path $_) } | select -First 1)
	    write-host "Using drive letter $script:MDLetter"
	    $phash = @{DriveLetter="$script:MDLetter" ;}
	    Set-WmiInstance -input $metavol -Arguments $phash
	}
	if (! (Test-Path ("$script:MDLetter" + "\meta-data")))
	{
	    $msg = "Could not find meta-data directory on $script:MDLetter"
	    $script:MDLetter = ""
	    throw $msg
	}
	# Make sure Metadata drive is not mounted readonly
	if ($vers -gt 2) {  ## also not needed for Windows Server 2008
	    Get-Disk | foreach {
		$adisk =  $_
		$_ | Get-Partition | foreach {
		    if ($_.DriveLetter -eq $script:MDLetter.trim(":")) {
			Write-Host "setting to readable: $adisk)"
			$adisk | Set-Disk -isreadonly:$false
		    }
		}
	    }
	}
    	# Output resulting disk status for debugging online/offline status
	"Testing 333" | Write-Host
	"list disk" | diskpart.exe 2>&1 | Write-Host
	"Testing 444" | Write-Host
    }
    $script:MDLetter
}

function Read_Metadata( $mdpath )
{
    $mdl = Get_MD_Letter
    [System.IO.File]::ReadAllText("$mdl\meta-data\$mdpath").trim()
}

function Get_Metadata_Mac_Addresses()
{
    $mdl = Get_MD_Letter
    (Get-ChildItem "$mdl\meta-data\network\interfaces\macs") | foreach {
       $_.Name
    }
}

function Set_Networking_From_Metadata( $macAddr )
{
    $macAddrColons = $_.replace("-",":")
    try {
	$metaIpv4 = Read_Metadata("network\interfaces\macs\$macAddr\local-ipv4s")
	$metaMask = Read_Metadata("network\interfaces\macs\$macAddr\x-netmask")
	$metaGateway = Read_Metadata("network\interfaces\macs\$macAddr\x-gateway")
	$metaDNS = Read_Metadata("network\interfaces\macs\$macAddr\x-dns")
	$wmi = Get-WmiObject win32_networkadapterconfiguration -filter "MACAddress = '$macAddrColons'"
	if ($wmi -eq $null) {
	    write-host "Could not find interface with MAC=$macAddrColons"
	} else {
	    write-host "Setting interface for ${macAddrColons}: IP=$metaIpv4, mask=$metaMask, gateway=$metaGateway"
	    $wmi.EnableStatic($metaIpv4, $metaMask)
	    $wmi.SetGateways($metaGateway, 1)
	    if ( $metaDNS -ne "" )
	    {		
		$wmi.SetDNSServerSearchOrder($metaDNS)
	    }
	}
    }
    catch {
	$Error[0] | Write-Host
	Write-Host "Error occurred while setting interface with MAC=$macAddrColons"
    }
}

# Set up networking
Get_Metadata_Mac_Addresses | foreach { Set_Networking_From_Metadata( $_ ) }
# The above can sometimes fail for multiple nics where one nic already has the
# intended setting as the nic the code is currently trying to set.  Windows
# seems to just ignore the request without thowing any errors.  The simple solution
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
    $randpass = [System.Web.Security.Membership]::GeneratePassword(12,2).ToCharArray()
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

"Finishing wakame-init-first-boot.ps1...about to do Stop-Computer" | Write-Host

# shutdown
Stop-Computer
