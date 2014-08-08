
"Starting wakame-init-every-boot.ps1" | Write-Host

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
	    # This does work with the version 2 PowerShell on Windows
	    # Server 2008, but may be unnecessary because the
	    # metadata disk is online by default.  Can't find any
	    # documentation to say why it should behave differently
	    # from Windows Server 2012.
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
	Get-Disk | foreach {
            $adisk =  $_
	    $_ | Get-Partition | foreach {
		if ($_.DriveLetter -eq $script:MDLetter.trim(":")) {
		    write-host "setting to readable: $adisk)"
		    $adisk | Set-Disk -isreadonly:$false
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
	Write-Host "Trying auto activation"
	cscript //b c:\windows\system32\slmgr.vbs /ato
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

"Finishing wakame-init-every-boot.ps1" | Write-Host
