#include <iostream>
#include <stdlib.h>
using namespace std;

int main()
{
	short a = 0xffff;
	for (short i = 0; i < 64; i++)
	{
		auto typetest = a << i;//使用auto作为取巧的方式来获取short类型移位后的数据类型，为int
		short temp = a << i;
		cout << hex << temp << endl;
	}
	int b = 0xffffffff;
	for (short i = 0; i < 64; i++)
	{
		auto temp = b << i;
		cout << hex << temp << endl;
	}
}

