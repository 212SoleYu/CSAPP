struct ELE{
	long v;
	struct ELE *p;
};

long fun(struct ELE *ptr)
{
	long result = 0;
	while(ptr!=0)
	{
		result += ptr->v;
		ptr = ptr->p;
	}
	return result;
}
