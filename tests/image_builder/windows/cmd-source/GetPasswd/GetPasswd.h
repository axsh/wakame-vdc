class GetPasswd
{
private:
	FILE* m_in;
	FILE* m_out;

public:
	GetPasswd(void);
	~GetPasswd(void);

	int parse(int argc, _TCHAR* argv[]);
	void usage(void);
	void print(void);
};