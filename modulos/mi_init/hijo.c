// SPDX-License-Identifier: GPL-2.0
#include <stdio.h>
#include <unistd.h>

int main(void)
{
	printf("hijo: soy el PID %d y mi padre es el PID %d\n", getpid(), getppid());
	return 7;
}
