int main()
{
	int a = 601;
	int b = 7528879;
	int64_t c = a * b;
	int64_t d = (int64_t)a * b;
	int64_t e = (int64_t)(a*b);//与c本质完全相同
	printf("%lld\n%lld\n%lld\n", c, d, e);
}
