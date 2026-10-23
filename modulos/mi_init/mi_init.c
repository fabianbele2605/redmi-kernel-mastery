// SPDX-License-Identifier: GPL-2.0
#include <stdio.h>
#include <unistd.h>
#include <sys/mount.h>
#include <sys/reboot.h>

static void mostrar(const char *ruta)
{
	char buf[256];
	FILE *f = fopen(ruta, "r");

	if (!f) {
		perror(ruta);
		return;
	}
	if (fgets(buf, sizeof(buf), f))
		printf("%s: %s", ruta, buf);
	fclose(f);
}

int main(void)
{
	mount("proc", "/proc", "proc", 0, NULL);
	printf("mi_init: hola, soy el PID %d\n", getpid());
	mostrar("/proc/uptime");
	mostrar("/proc/version");
	printf("mi_init: apagando\n");
	sync();
	reboot(RB_POWER_OFF);
	return 1;
}
