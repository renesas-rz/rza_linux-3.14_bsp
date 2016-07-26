/*
 * 
 */
#define _POSIX_C_SOURCE		200112L

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <sys/time.h>
#include <unistd.h>

enum {
	LOOP = 20,
};

static long difftimeval(struct timeval *tv1, struct timeval *tv2)
{
	long usec;

	usec = (tv2->tv_sec - tv1->tv_sec) * 1000000;
	usec += ((long)tv2->tv_usec - (long)tv1->tv_usec);
	return usec;
}

int main(int argc, const char *argv[])
{
	struct timeval tv[LOOP];
	struct timespec req;
	int i;

	req.tv_sec = 0;
	req.tv_nsec = 1000;	/* 1us */

	for (i = 0; i < LOOP; i++) {
		if (nanosleep(&req, NULL)) {
			fprintf(stderr, "%s: nanosleep() failed at %d\n", argv[0], i);
			exit(1);
		}
		if (gettimeofday((tv + i), NULL)) {
			fprintf(stderr, "%s: gettimeofaday() failed at %d\n", argv[0], i);
			exit(1);
		}
	}

	for (i = 0; i < LOOP; i++) {
		if (i == 0) {
			printf("%ld:%06ld\n", (long)tv[i].tv_sec, (long)tv[i].tv_usec);
		} else {
			printf("%ld:%06ld (0.%06ld)\n", (long)tv[i].tv_sec, (long)tv[i].tv_usec,
				difftimeval(&tv[i - 1], &tv[i]));
		}
	}
	return 0;
}
