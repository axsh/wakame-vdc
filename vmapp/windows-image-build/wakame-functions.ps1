
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
    $Encode = New-Object "System.Text.UTF8Encoding"
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
	    Write-Host "Using drive letter $script:MDLetter"
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
	    Write-Host "Could not find interface with MAC=$macAddrColons"
	} else {
	    Write-Host "Setting interface for ${macAddrColons}: IP=$metaIpv4, mask=$metaMask, gateway=$metaGateway"
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

function Update_Hosts_File
{
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
}

function Try_Auto_Activation
{
    $mdl = Get_MD_Letter
    if (Test-Path ("$mdl\meta-data\auto-activate")) # does *directory* exist?
    {
	try {
	    $proxy = ""
	    if (Test-Path ("$mdl\meta-data\auto-activate\auto-activate-proxy")) {
		$proxy = Read_Metadata("auto-activate\auto-activate-proxy")
		Write-Host "Setting proxy to $proxy."
		# contents of auto-activate-proxy should be IP:PORT, e.g.: 10.1.3.44:8888
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
}
