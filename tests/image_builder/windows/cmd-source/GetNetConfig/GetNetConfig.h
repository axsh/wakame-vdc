class GetNetConfig {

private:
	TCHAR m_szIntefaceName[MAX_PATH];
	TCHAR m_szMAC_Address[MAX_PATH];
	PIP_ADAPTER_INFO m_pAdapter;
	BOOL m_bTitle;
	int m_nOptions;
	int m_nMatches;
	TCHAR m_szCheck_IntefaceName[MAX_PATH];
	TCHAR m_szCheck_MAC_Address[MAX_PATH];
	TCHAR m_szCheck_IP_Address[16];
	TCHAR m_szCheck_MASK_Address[16];
	TCHAR m_szCheck_Gateway_Address[16];
	TCHAR m_szCheck_DNS_Address[16];

	void PrintWinAPI_error(LONG lResult);
	BOOL IsWindows2000(void);
	BOOL GetStringFromRegistry(BOOL Is64KeyRequired, HKEY hRootKey,
		LPCSTR lpszPath, LPCSTR lpszKeyName, LPBYTE lpszValue, DWORD dwSize);
	void GetInterfaceName(char adapterName[]);
	void GetMACaddress(unsigned char MACData[]);

	void PrintInterfaceName(void);
	void PrintAdapterInfo(PIP_ADAPTER_INFO pAdapter);
	void PrintName(void);
	void PrintMACaddress(void);
	void PrintIndex(void);
	void PrintIPV4Address(void);
	void PrintMaskAddress(void);
	void PrintGatewayAddress(void);
	void PrintDNSAddress(void);
	BOOL FindDNSAddress(PIP_ADAPTER_INFO pAdapter);
	void PrintDHCP(void);
	void PrintWINS(void);


public:
	GetNetConfig();

	int parse(int argc, _TCHAR* argv[]);
	void usage(void);
	void print(void);

};