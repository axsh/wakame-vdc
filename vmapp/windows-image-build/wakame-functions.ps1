# All external commands are piped through Write-Host so they do
# not access stdout and stderr directly, which avoids a bug in
# PowerShell in Windows Server 2008.
# see: http://www.leeholmes.com/blog/2008/07/30/workaround-the-os-handles-position-is-not-what-filestream-expected/

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
	Bring_All_Disks_Online
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
	if ($vers -gt 2) {  ## Only needed for 2012, which does support Get-Disk
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

function Bring_All_Disks_Online()
{
    # This code should work for both PowerShell on both Windows Server 2008 and 2012
    "Bringing all disks online.  Errors below for disks already online is normal." | Write-Host
    Get-WmiObject -class win32_diskdrive | foreach {
	$diskID=$_.index
	# hints from: http://winblog.ch/2012/02/28/using-wmi-to-bring-disks-online/
	"select disk $diskID", "online disk noerr" | diskpart 2>&1 | Write-Host
    }
}

function Take_Metadata_Offline()
{
    $mdl = Get_MD_Letter
    if ( $script:MDLetter -eq "" ) {
	Write-Host "Take_Metadata_Offline called without the metadrive's letter being set"
	return
    }
    try {
	$justLetter = $script:MDLetter.trim(":")
	# A disk must be selected before the "offline disk" command
        # will work.  Correctly selecting the metadata drive disk is a
        # little tricky, but selecting the volume it is on is easy
        # because the "select volume" can take a drive letter as an
        # argument.  Fortunately, it also selects the disk, although
        # this effect seems to be undocumented.
	# (And we must use diskpart, because get-disk and set-disk
	# are not in Powershell 2 on Windows 2008)
	"select volume=$justLetter", "offline disk" | diskpart 2>&1 | Write-Host
    }
    catch {
	$Error[0] | Write-Host
	Write-Host "Error occurred while taking meta-data drive offline"
    }
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

function Generate_Password
{
    try {
	# Generate password
	$mdl = Get_MD_Letter
	Add-Type -AssemblyName System.Web
	$NotSet = $true

	# Although we use the Windows built-in GeneratePassword
	# function for generating random passwords, it is still
	# possible for it to generate a password that does not meet
	# Windows password complexity requirements. In such a case,
	# SetPassword will throw an exception. The code below will
	# catch the exception and will try again. A test of
	# GeneratePassword(10,2) produced an unacceptable password on
	# average every 105 iterations, so 10 attempts should succeed
	# with almost certainty (1 in 1.6538867745659126e+20).  This
	# solution is a bit hackish, but has the advantage of not
	# having to really understand Windows password rules and
	# worrying that the rules could possibly change.

	$attemptsLeft=10 # default max number of attempts
	if (Test-Path ("$mdl\meta-data\retry-gen-password")) {
	    $retryString = Read_Metadata("retry-gen-password")
	    $attemptsLeft = [int] $retryString
	}

	while ( $NotSet -and $attemptsLeft -gt 0 ) {
	    try {
		$attemptsLeft = $attemptsLeft - 1

		$randpass = [System.Web.Security.Membership]::GeneratePassword(10,2).ToCharArray()
		$Encode = New-Object "System.Text.UTF8Encoding"
		$randpasstxt = $Encode.GetString([byte[]] $randpass)

		# Change Administrator password
		$computer=hostname
		$username="Administrator"
		$user = [adsi]"WinNT://$computer/$username,user"
		$user.SetPassword($randpasstxt)
		$user.SetInfo()
		$NotSet = $false  # exit loop
	    }
	    catch {
		$Error[0] | Write-Host
		Write-Host "Error occurred while setting Administrator password ($attemptsLeft attempts left)"
	    }
	}
    }
    catch {
	$Error[0] | Write-Host
	Write-Host "Error in setup for changing Administrator password "
    }

    if ( $NotSet ) { return }
    try {
	# Encrypt password
	$MetaSshpub = Read_Metadata("public-keys\0\openssh-key")
	$XmlPublicKey =  sshpubkey2xml( $MetaSshpub )
	$rsaProvider = New-Object System.Security.Cryptography.RSACryptoServiceProvider
	$rsaProvider.FromXmlString($XmlPublicKey.InnerXml)
	$ee = $rsaProvider.Encrypt($randpass,$true)
	[System.IO.File]::WriteAllBytes("$mdl\meta-data\pw.enc",$ee)
    }
    catch {
	$Error[0] | Write-Host
	Write-Host "Error occurred while encrypting Administrator password"
    }
}
