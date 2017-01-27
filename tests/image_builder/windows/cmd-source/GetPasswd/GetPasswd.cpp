// setRandamPassword.cpp : コンソール アプリケーションのエントリ ポイントを定義します。
//

#include "stdafx.h"
#include "GetPasswd.h"


int _tmain(int argc, _TCHAR* argv[])
{
	GetPasswd app;
	int ret = app.parse(argc,argv);
	if (ret != 0) {
		if (ret == -1) {
			app.usage();
		}
		return ret;
	}
	app.print();
	return 0;
}

GetPasswd::GetPasswd(void)
{
	m_in = stdin;
	m_out = stdout;
}
GetPasswd::~GetPasswd(void)
{
	if (m_in != stdin) {
		fclose(m_in);
	}
	if (m_out != stdout) {
		fclose(m_out);
	}
}

void GetPasswd::usage(void)
{
	_tprintf(_T("Usage GetPasswd\n"));
	_tprintf(_T("\t-help\tThis information\n"));
	_tprintf(_T("\t-in file\tset input filename\n"));
	_tprintf(_T("\t-out file\tset output file\n"));
	_tprintf(_T("\n"));
	_tprintf(_T("ex)\n"));
	_tprintf(_T("@echo aaaa: bbbb| GetPasswd \n"));
	_tprintf(_T("\tprint stdout bbbb\n"));
}

int GetPasswd::parse(int argc, _TCHAR* argv[])
{
	for (int i = 1; i < argc;i++) {
		CString strArg = argv[i];
		strArg = strArg.MakeLower();
		if (strArg.Compare(_T("-help")) == 0) {
			return -1;
		}
		if (strArg.Compare(_T("-in")) == 0) {
			if (argc < i + 1) {
				return -1;
			}
			CString in_file = argv[++i];
			errno_t error;
			FILE* fp;
			LPCTSTR in_lpstr = in_file; 
			error = _tfopen_s(&fp, in_lpstr, _T("rt"));
			if (error != 0) {
				_tprintf(_T("infile(%s) is not open!!(errono=%d)\n"),
					in_lpstr, error);
				return -2;
			}
			m_in = fp;

		}
		if (strArg.Compare(_T("-out")) == 0) {
			if (argc < i + 1) {
				return -1;
			}
			CString out_file = argv[++i];
			errno_t error;
			FILE* fp;
			LPCTSTR out_lpstr = out_file; 
			error = _tfopen_s(&fp, out_lpstr, _T("wt"));
			if (error != 0) {
				_tprintf(_T("outfile(%s) is not open!!(errono=%d)\n"),
					out_lpstr, error);
				return -2;
			}
			m_out = fp;

		}
	}
	return 0;
}

void GetPasswd::print(void)
{
	TCHAR in_line[MAX_PATH];

	while (NULL != _fgetts(in_line, sizeof(in_line), m_in)) {
		CString strLine = in_line;
		int pos = strLine.Find(_T(": "));
		if (pos == -1) {
			continue;
		}
		CString strPass = strLine.Mid(pos+2);
		_fputts((LPCTSTR)strPass, m_out);
	}
}
