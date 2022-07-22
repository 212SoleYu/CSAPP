#include <iostream>
#include <stdlib.h>
using namespace std;

typedef unsigned char *byte_pointer;

void show_bytes(byte_pointer start,int len)
{
	int i;
	for (int i = 0; i < len; i++)
	{
		printf("%.2x", start[i]);
	}
	printf("\n");
}
void show_int(int x)
{
	show_bytes((byte_pointer)&x, sizeof(int));
}
void show_float(float x)
{
	show_bytes((byte_pointer)&x, sizeof(float));
}
void show_pointer(void* x)
{
	show_bytes((byte_pointer)&x, sizeof(void*));
}
int main()
{
	int a = 0x12345678;
	int* p = &a;
	float f = 3.14;
	printf("%x\n", a);
	show_int(a);
	printf("%f\n", f);
	show_float(f);
	printf("%x\n", p);
	show_pointer(p);
}

