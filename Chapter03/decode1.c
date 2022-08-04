void decode1(long *xp, long *yp,long* zp)
{
	long tx = *xp;
	long ty = *yp;
	long tz = *zp;
	*xp = ty;
	*yp = tz;
	*zp = tx;
	return;
}
