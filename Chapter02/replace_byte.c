unsigned replace_byte(unsigned x, int i, unsigned char b)
{
	int mask = 0xff << (i * 8);
	return mask & (b << (i * 8)) | x & (~mask);
}
int main()
{
	int x = 0x89ABCDEF;
	int y = 0x76543210;
	int mask = 0xff;
	int ans = x & mask | y & ~mask;
	printf("%x\n", ans);
	int c = replace_byte(0x12345678, 0, 0xAB);
	printf("%x\n", c);

}
