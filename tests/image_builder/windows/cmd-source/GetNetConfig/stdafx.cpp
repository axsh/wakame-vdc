// stdafx.cpp : source file that includes just the standard includes
// GetMACAdapters.pch will be the pre-compiled header
// stdafx.obj will contain the pre-compiled type information

#include "stdafx.h"

// TODO: reference any additional headers you need in STDAFX.H
// and not in this file
void StrSplit(CString str, CString delim, CSimpleArray<CString> &result)
{
	result.RemoveAll();

	int indexback = 0;

	CString st;

	int i = 0;
	for(i = 0; i <str.GetLength(); i++)
	{
		if (str.GetAt(i) == delim.GetAt(0)) {
			if ((i - indexback) == 0) {
				result.Add("");
			}
			else {
				st = str.Mid(indexback, i - indexback);
				result.Add(st);
			}
			indexback = i + 1;
		}
	}

	if ((i - indexback) != 0) {
		st = str.Mid(indexback, i - indexback);
		result.Add(st);
	}

}
