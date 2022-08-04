#include<stdio.h>

int maxN_32()
{
	int n = 0;
	int result = 1;
	int pre = 0;
	do{
		pre = result;
		n+=1;
		result*=n;		
	}while(result/n==pre);
	return n-1;
}

int maxN_64()
{
	int n =0;
	long result = 1;
	long pre = 0;
	do{
		pre = result;
		n+=1;		
		result*=n;		
	}while(result/n==pre);
	return n-1;
}

int main()
{
	int a = maxN_32();
	int b = maxN_64();
	printf("%d\n%d\n",a,b);
	return 0;
}
