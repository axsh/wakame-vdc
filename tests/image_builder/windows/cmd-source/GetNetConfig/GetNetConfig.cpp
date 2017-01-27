// GetMACAdapters.cpp : Defines the entry point for the console application.
//
// Author:	Khalid Shaikh [Shake@ShakeNet.com]
// Date:	April 5th, 2002
//
// This program fetches the MAC address of the localhost by fetching the 
// information through GetAdapatersInfo.  It does not rely on the NETBIOS
// protocol and the ethernet adapter need not be connect to a network.
//
// Supported in Windows NT/2000/XP
// Supported in Windows 95/98/Me
//
// Supports multiple NIC cards on a PC.

#include "stdafx.h"
#include <Windows.h>
#include <Iphlpapi.h>
#include <Assert.h>
#pragma comment(lib, "iphlpapi.lib")

#include "GetNetConfig.h"

enum print_type {
	pt_ifname = 0x01,
	pt_name = 0x02,
	pt_mac = 0x04,
	pt_ipv4 = 0x08,
	pt_mask = 0x10,
	pt_gateway = 0x20,
	pt_dns = 0x40,
	pt_other = 0x80

};

int _tmain(int argc, _TCHAR* argv[])
{
	GetNetConfig app;
	int ret = app.parse(argc, argv);
	if (ret != 0) {
		app.usage();
		return ret;
	}
	app.print();

	return 0;
}

/**
* コンストラクタ
*/
GetNetConfig::GetNetConfig()
{
	m_bTitle = TRUE;
	m_nOptions = pt_ifname | pt_name | pt_mac | pt_ipv4 | pt_mask | pt_gateway | pt_dns | pt_other;
	m_nMatches = 0x0;
}

void GetNetConfig::usage()
{
	printf("Usage GetNetConfig\n");
	printf("\t-help\tThis information\n");
	printf("\t-ifname\tXXXXX match interface name only\n");
	printf("\t-name\tXXXXX match adapter name only\n");
	printf("\t-mac\tXX:XX:XX:XX:XX match mac address only\n");
	printf("\t-ipv4\tXXX.XXX.XXX.XXX match ipv4 address only\n");
	printf("\t-mask\tXXX.XXX.XXX.XXX match mask address only\n");
	printf("\t-gw\tXXX.XXX.XXX.XXX match gateway address only\n");
	printf("\t-dns\tXXX.XXX.XXX.XXX match dns address only\n");
	printf("\t-print ifname,name,mac,ipv4,mask,gw,dns,other\n");
	printf("\t-notitle\tTitle not show\n");
}

int GetNetConfig::parse(int argc, _TCHAR* argv[])
{
	for (int i = 1; i < argc;i++) {
		CString strArg = argv[i];
		strArg = strArg.MakeLower();
		if (strArg.Compare(_T("-help")) == 0) {
			return -1;
		}
		if (strArg.Compare(_T("-mac")) == 0) {
			if (argc < i + 1) {
				return -1;
			}
			CString mac = argv[++i];
			mac = mac.MakeUpper();
			if (mac.GetLength() != 17) {
				return -1;
			}
			m_nMatches |= pt_mac;
			sprintf_s(m_szCheck_MAC_Address, sizeof(m_szCheck_MAC_Address),
				"%s", mac);

		}
		if (strArg.Compare(_T("-ifname")) == 0) {
			if (argc < i + 1) {
				return -1;
			}
			CString ifname = argv[++i];
			if (ifname.GetLength() > MAX_PATH) {
				return -1;
			}
			m_nMatches |= pt_ifname;
			sprintf_s(m_szCheck_IntefaceName, sizeof(m_szCheck_IntefaceName),
				"%s", ifname);

		}
		if (strArg.Compare(_T("-ipv4")) == 0) {
			if (argc < i + 1) {
				return -1;
			}
			CString ip = argv[++i];
			if (ip.GetLength() > 15) {
				return -1;
			}
			m_nMatches |= pt_ipv4;
			sprintf_s(m_szCheck_IP_Address, sizeof(m_szCheck_IP_Address),
				"%s", ip);

		}
		if (strArg.Compare(_T("-mask")) == 0) {
			if (argc < i + 1) {
				return -1;
			}
			CString mask = argv[++i];
			if (mask.GetLength() > 15) {
				return -1;
			}
			m_nMatches |= pt_mask;
			sprintf_s(m_szCheck_MASK_Address, sizeof(m_szCheck_MASK_Address),
				"%s", mask);

		}
		if (strArg.Compare(_T("-gw")) == 0) {
			if (argc < i + 1) {
				return -1;
			}
			CString gateway = argv[++i];
			if (gateway.GetLength() > 15) {
				return -1;
			}
			m_nMatches |= pt_gateway;
			sprintf_s(m_szCheck_Gateway_Address, sizeof(m_szCheck_Gateway_Address),
				"%s", gateway);

		}
		if (strArg.Compare(_T("-dns")) == 0) {
			if (argc < i + 1) {
				return -1;
			}
			CString dns = argv[++i];
			if (dns.GetLength() > 15) {
				return -1;
			}
			m_nMatches |= pt_dns;
			sprintf_s(m_szCheck_DNS_Address, sizeof(m_szCheck_DNS_Address),
				"%s", dns);

		}
		if (strArg.Compare(_T("-print")) == 0) {
			if (argc < i + 1) {
				return -1;
			}
			m_nOptions = 0x0;
			CString option = argv[++i];
			CSimpleArray<CString> options;
			StrSplit(option, _T(","), options);
			if (options.GetSize() == 0) {
				return -1;
			}
			for (int ii = 0; ii < options.GetSize();ii++) {
				CString strOpt = options[ii];
				strOpt = strOpt.MakeLower();
				if (strOpt.Compare(_T("ifname")) == 0) {
					m_nOptions |= pt_ifname;
				}
				else if (strOpt.Compare(_T("name")) == 0) {
					m_nOptions |= pt_name;
				}
				else if (strOpt.Compare(_T("mac")) == 0) {
					m_nOptions |= pt_mac;
				}
				else if (strOpt.Compare(_T("ipv4")) == 0) {
					m_nOptions |= pt_ipv4;
				}
				else if (strOpt.Compare(_T("mask")) == 0) {
					m_nOptions |= pt_mask;
				}
				else if (strOpt.Compare(_T("gw")) == 0) {
					m_nOptions |= pt_gateway;
				}
				else if (strOpt.Compare(_T("dns")) == 0) {
					m_nOptions |= pt_dns;
				}
				else if (strOpt.Compare(_T("other")) == 0) {
					m_nOptions |= pt_other;
				}
				else {
					return -1;
				}
			}
			if (m_nOptions == 0x0) {
				return -1;
			}

		}
		if (strArg.Compare(_T("-notitle")) == 0) {
			m_bTitle = FALSE;
		}
	}
	return 0;
}

void GetNetConfig::PrintWinAPI_error(LONG lResult)
{
	LPVOID lpMsgBuf;
	FormatMessage(
		FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, 
		NULL, 
		lResult, 
		LANG_USER_DEFAULT, 
		(LPSTR)&lpMsgBuf,
		0,
		NULL);
	printf("%s", lpMsgBuf);
	LocalFree(lpMsgBuf);
}

BOOL GetNetConfig::IsWindows2000(void)
{
    DWORD dwVersion = GetVersion();

    if (LOBYTE(LOWORD(dwVersion)) == 5 &&
        HIBYTE(LOWORD(dwVersion)) == 0)
        return TRUE;
    return FALSE;
}

BOOL GetNetConfig::GetStringFromRegistry(
	BOOL Is64KeyRequired,
    HKEY hRootKey,
    LPCSTR lpszPath,
    LPCSTR lpszKeyName,
    LPBYTE lpszValue,
    DWORD dwSize
	)
{
    REGSAM samDesired = KEY_READ;
    HKEY hKey;

    /* Check Win2000 (KEY_WOW64_64KEY - not supported) */
    if (!IsWindows2000() && Is64KeyRequired)
    {
        samDesired |= KEY_WOW64_64KEY;
    }

	LONG lResult;

	lResult = RegOpenKeyEx(hRootKey, lpszPath, 0, samDesired, &hKey);
    if (lResult != ERROR_SUCCESS)
    {
		PrintWinAPI_error(lResult);
		return FALSE;
	}

	lResult = RegQueryValueEx(hKey, lpszKeyName, NULL, NULL, lpszValue, &dwSize);
    if (lResult != ERROR_SUCCESS)
    {
		PrintWinAPI_error(lResult);
        RegCloseKey(hKey);
		return FALSE;
	}
    RegCloseKey(hKey);
    return TRUE;
}

void GetNetConfig::GetInterfaceName(char adapterName[])
{
	TCHAR szKey[MAX_PATH];
	sprintf_s(
		(char*)szKey, sizeof(szKey),
        _T("SYSTEM\\CurrentControlSet\\Control\\Network\\{4D36E972-E325-11CE-BFC1-08002BE10318}\\%s\\Connection"),
         adapterName);
    if (!GetStringFromRegistry(
		TRUE,
		HKEY_LOCAL_MACHINE,
        szKey, _T("Name"),
        (LPBYTE)m_szIntefaceName, MAX_PATH))
    {
        return;
    }


}

void GetNetConfig::PrintInterfaceName(void)
{
	if ((m_nOptions & pt_ifname) != pt_ifname) {
		return;
	}
	if (m_bTitle == TRUE) {
		printf("InterfaceName: \t");
	}
	printf("%s\n", 
		m_szIntefaceName);

}

void GetNetConfig::GetMACaddress(unsigned char MACData[])
{
	//12-45-78-01-34
	sprintf_s(
		(char*)m_szMAC_Address, sizeof(m_szMAC_Address),
		"%02X-%02X-%02X-%02X-%02X-%02X", 
		MACData[0], MACData[1], MACData[2], MACData[3], MACData[4], MACData[5]);
}

// Prints the MAC address stored in a 6 byte array to stdout
void GetNetConfig::PrintMACaddress(void)
{
	if ((m_nOptions & pt_mac) != pt_mac) {
		return;
	}
	if (m_bTitle == TRUE) {
		printf("\tMAC Address: \t");
	}
	//12-45-78-01-34
	printf("%s\n", 
		m_szMAC_Address);
}

void GetNetConfig::PrintDHCP(void)
{
	struct tm newtime;
    char buffer[32];
	errno_t error;

	if ((m_nOptions & pt_other) != pt_other) {
		return;
	}
    if (m_bTitle == TRUE) {
		printf("\tDHCP Enabled: \t");
	}
	if (!m_pAdapter->DhcpEnabled) {
        printf("No\n");
		return;
	}

    printf("Yes\n");
    if (m_bTitle == FALSE) {
		return;
	}
    printf("\t  DHCP Server: \t%s\n",
            m_pAdapter->DhcpServer.IpAddress.String);

    printf("\t  Lease Obtained: ");
    /* Display local time */
    error = _localtime32_s(&newtime, (__time32_t*) &m_pAdapter->LeaseObtained);
    if (error) {
        printf("Invalid Argument to _localtime32_s\n");
	}
    else {
        // Convert to an ASCII representation 
        error = asctime_s(buffer, 32, &newtime);
        if (error) {
            printf("Invalid Argument to asctime_s\n");
		}
        else {
            /* asctime_s returns the string terminated by \n\0 */
            printf("%s", buffer);
		}
    }

    printf("\t  Lease Expires:  ");
    error = _localtime32_s(&newtime, (__time32_t*) &m_pAdapter->LeaseExpires);
    if (error) {
        printf("Invalid Argument to _localtime32_s\n");
	}
    else {
        // Convert to an ASCII representation 
        error = asctime_s(buffer, 32, &newtime);
        if (error) {
            printf("Invalid Argument to asctime_s\n");
		}
		else {
            /* asctime_s returns the string terminated by \n\0 */
            printf("%s", buffer);
		}
    }
}

void GetNetConfig::PrintWINS(void)
{
	if ((m_nOptions & pt_other) != pt_other) {
		return;
	}
    if (m_bTitle == TRUE) {
        printf("\tHave Wins\t");
	}
    if (!m_pAdapter->HaveWins) {
        printf("No\n");
		return;
	}

	printf("Yes\n");
    if (m_bTitle == FALSE) {
		return;
	}
    printf("\t  Primary Wins Server:    %s\n",
            m_pAdapter->PrimaryWinsServer.IpAddress.String);
    printf("\t  Secondary Wins Server:  %s\n",
            m_pAdapter->SecondaryWinsServer.IpAddress.String);
}

void GetNetConfig::PrintIPV4Address(void)
{
	if ((m_nOptions & pt_ipv4) != pt_ipv4) {
		return;
	}
    if (m_bTitle == TRUE) {
	    printf("\tIP Address: \t");
	}

    printf("%s\n",
            m_pAdapter->IpAddressList.IpAddress.String);
}

void GetNetConfig::PrintMaskAddress(void)
{
	if ((m_nOptions & pt_mask) != pt_mask) {
		return;
	}
    if (m_bTitle == TRUE) {
	    printf("\tIP Mask: \t");
	}

    printf("%s\n",
            m_pAdapter->IpAddressList.IpMask.String);

}

void GetNetConfig::PrintGatewayAddress(void)
{
	if ((m_nOptions & pt_gateway) != pt_gateway) {
		return;
	}
    if (m_bTitle == TRUE) {
	    printf("\tGateway: \t");
	}

    printf("%s\n",
            m_pAdapter->GatewayList.IpAddress.String);

}

void GetNetConfig::PrintDNSAddress(void)
{
	if ((m_nOptions & pt_dns) != pt_dns) {
		return;
	}

	if (m_pAdapter->Index <= 0) {
		return;
	}
	ULONG outBufLen = 0;
    GetPerAdapterInfo(m_pAdapter->Index, NULL, &outBufLen);
	if (outBufLen <= 0) {
		return;
	}
	IP_PER_ADAPTER_INFO* pPerAdapterInfo = (IP_PER_ADAPTER_INFO*) malloc(outBufLen);
    DWORD dwResult = GetPerAdapterInfo(m_pAdapter->Index, pPerAdapterInfo, &outBufLen);
	if (dwResult != ERROR_SUCCESS) {
		free(pPerAdapterInfo);
		return;
	}

    if (m_bTitle == TRUE) {
	    printf("\tDNS Address: \t");
	}

	IP_ADDR_STRING* pDns = &pPerAdapterInfo->DnsServerList;

    // loop through all DNS IPs
	int i = 0;
    while (pDns) {
		if (i > 0) {
			printf(", ");
		}
		printf("%s",
				pDns->IpAddress.String);

        pDns = pDns->Next;
		i++;
	}
	printf("\n");

	free(pPerAdapterInfo);
}

BOOL GetNetConfig::FindDNSAddress(PIP_ADAPTER_INFO pAdapter)
{
	if (pAdapter->Index <= 0) {
		return FALSE;
	}
	ULONG outBufLen = 0;
    GetPerAdapterInfo(pAdapter->Index, NULL, &outBufLen);
	if (outBufLen <= 0) {
		return FALSE;
	}
	IP_PER_ADAPTER_INFO* pPerAdapterInfo = (IP_PER_ADAPTER_INFO*) malloc(outBufLen);
    DWORD dwResult = GetPerAdapterInfo(pAdapter->Index, pPerAdapterInfo, &outBufLen);
	if (dwResult != ERROR_SUCCESS) {
		free(pPerAdapterInfo);
		return FALSE;
	}

	IP_ADDR_STRING* pDns = &pPerAdapterInfo->DnsServerList;

    // loop through all DNS IPs
    while (pDns) {
		if (strcmp(m_szCheck_DNS_Address, pDns->IpAddress.String) == 0) {
			free(pPerAdapterInfo);
			return TRUE;
		}

        pDns = pDns->Next;
	}

	free(pPerAdapterInfo);
	return FALSE;
}

void GetNetConfig::PrintName(void)
{
	if ((m_nOptions & pt_name) != pt_name) {
		return;
	}
    if (m_bTitle == TRUE) {
		printf("\tAdapter Name: \t");
	}
    printf("%s\n", m_pAdapter->AdapterName);
    if (m_bTitle == FALSE) {
		return;
	}
    printf("\tAdapter Desc: \t%s\n", m_pAdapter->Description);
}

void GetNetConfig::PrintIndex(void)
{
	if ((m_nOptions & pt_other) != pt_other) {
		return;
	}

	//printf("\tComboIndex: \t5d\n", m_pAdapter->ComboIndex);
    if (m_bTitle == TRUE) {
		printf("\tIndex: \t");
	}
    printf("%d\n", m_pAdapter->Index);
    if (m_bTitle == FALSE) {
		return;
	}
    printf("\tType: \t");
    switch (m_pAdapter->Type) {
    case MIB_IF_TYPE_OTHER:
        printf("Other\n");
        break;
    case MIB_IF_TYPE_ETHERNET:
        printf("Ethernet\n");
        break;
    case MIB_IF_TYPE_TOKENRING:
        printf("Token Ring\n");
        break;
    case MIB_IF_TYPE_FDDI:
        printf("FDDI\n");
        break;
    case MIB_IF_TYPE_PPP:
        printf("PPP\n");
        break;
    case MIB_IF_TYPE_LOOPBACK:
        printf("Lookback\n");
        break;
    case MIB_IF_TYPE_SLIP:
        printf("Slip\n");
        break;
    default:
        printf("Unknown type %ld\n", m_pAdapter->Type);
        break;
    }
}

void GetNetConfig::PrintAdapterInfo(PIP_ADAPTER_INFO pAdapter)
{
	m_pAdapter = pAdapter;
	
	PrintName();		// Print Adepter Name & Description
	PrintMACaddress();	// Print MAC address
	PrintIndex();		// Print Combo Index & Index

	PrintIPV4Address();
	PrintMaskAddress();
	PrintGatewayAddress();
	PrintDNSAddress();
    if ((m_nOptions & pt_other) == pt_other) {
		printf("\n");
	}

	PrintDHCP();
	PrintWINS();

}

// Fetches the MAC address and prints it
void GetNetConfig::print(void)
{
	IP_ADAPTER_INFO AdapterInfo[16];			// Allocate information for up to 16 NICs
	DWORD dwBufLen = sizeof(AdapterInfo);		// Save the memory size of buffer

	DWORD dwStatus = GetAdaptersInfo(			// Call GetAdapterInfo
		AdapterInfo,							// [out] buffer to receive data
		&dwBufLen);								// [in] size of receive data buffer
	assert(dwStatus == ERROR_SUCCESS);			// Verify return value is valid, no buffer overflow

	PIP_ADAPTER_INFO pAdapterInfo = AdapterInfo;// Contains pointer to current adapter info
	do {
		GetInterfaceName(pAdapterInfo->AdapterName);
		GetMACaddress(pAdapterInfo->Address);

		if (((m_nMatches & pt_ifname) != pt_ifname ||
			((m_nMatches & pt_ifname) == pt_ifname && strcmp(m_szCheck_IntefaceName, m_szIntefaceName) == 0)) &&
			((m_nMatches & pt_mac) != pt_mac ||
			((m_nMatches & pt_mac) == pt_mac && strcmp(m_szCheck_MAC_Address, m_szMAC_Address) == 0 )) &&
			((m_nMatches & pt_ipv4) != pt_ipv4 ||
			((m_nMatches & pt_ipv4) == pt_ipv4 && strcmp(m_szCheck_IP_Address, pAdapterInfo->IpAddressList.IpAddress.String) == 0 )) &&
			((m_nMatches & pt_mask) != pt_mask ||
			((m_nMatches & pt_mask) == pt_mask && strcmp(m_szCheck_MASK_Address, pAdapterInfo->IpAddressList.IpMask.String) == 0 )) &&
			((m_nMatches & pt_gateway) != pt_gateway ||
			((m_nMatches & pt_gateway) == pt_gateway && strcmp(m_szCheck_Gateway_Address, pAdapterInfo->GatewayList.IpAddress.String) == 0 )) &&
			((m_nMatches & pt_dns) != pt_dns ||
			((m_nMatches & pt_dns) == pt_dns && FindDNSAddress(pAdapterInfo) == TRUE ))
			) {
			PrintInterfaceName();
			PrintAdapterInfo(pAdapterInfo);
		}
		pAdapterInfo = pAdapterInfo->Next;		// Progress through linked list
	}
	while(pAdapterInfo);						// Terminate if last adapter
}

