// SPDX-License-Identifier: GPL-2.0
#include <stdio.h>
#include <unistd.h>
#include <sys/mount.h>
#include <sys/reboot.h>
#include <sys/wait.h>

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
	pid_t pid = fork();

    if (pid == 0) {
        execl("/hijo", "hijo", (char *)NULL);
        perror("execl");
        _exit(127);
    }
    int estado = 0;

    waitpid(pid, &estado, 0);
    printf("mi_init: el hijo %d termino con codigo %d\n", pid, WEXITSTATUS(estado));
    printf("mi_init: apagando\n");
	sync();
	reboot(RB_POWER_OFF);
	return 1;
}
