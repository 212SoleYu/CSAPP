long fun_b(unsigned long x)
{
	long val = 0;
	long i;
	for(i = 64;i!=0;i--)
	{
		long temp = x;
		temp = temp & 0x1;
		val = val+val;
		val = val | temp;
		x=x>>1;
	}
	return val;
}
