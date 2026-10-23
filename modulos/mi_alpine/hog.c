// SPDX-License-Identifier: GPL-2.0
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void)
{
	size_t mib = 0;

	for (;;) {
		char *p = malloc(1024 * 1024);

		if (!p) {
			printf("hog: malloc fallo tras %zu MiB\n", mib);
			return 2;
		}
		memset(p, 1, 1024 * 1024);
		mib++;
		printf("hog: reservados y tocados %zu MiB\n", mib);
		fflush(stdout);
	}
}
