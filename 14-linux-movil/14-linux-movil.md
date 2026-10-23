# Módulo 14 — Más allá de Android: Linux móvil

- Estado: En progreso (investigación de compatibilidad y respaldos hechos; QEMU pendiente)
- Fecha: 2026-10-23
- Teléfono: Redmi Note 11 (`spes`), modelo `2201117TL`, variante **`spes-sm5602`** (`qcom,board-id` = `0004 0022`), kernel `4.19.297-uvite` con root de KernelSU (módulo 13, solo mientras dure el `fastboot boot`)
- Objetivo: entender el sistema completo, no solo el kernel, y averiguar **si este teléfono puede correr un Linux móvil** antes de cambiarle nada. Se hace en etapas, de menos a más riesgo, y **primero en QEMU**.

## Concepto

Android es un sistema de espacio de usuario (`system`, `vendor`, `product` dentro de la partición `super`) sobre un kernel Linux. Un «Linux móvil» (postmarketOS/Nura, Mobian, Ubuntu Touch...) sustituye ese espacio de usuario por uno basado en una distribución de escritorio (Alpine, Debian...), con una interfaz táctil (Phosh, Plasma Mobile...). Puede ir sobre el **kernel del fabricante** (el 4.19, con todos los controladores de Xiaomi pero abandonado) o sobre un **kernel principal moderno** (*mainline*), que exige que cada pieza de hardware tenga controlador en el Linux oficial.

## Práctica guiada

```bash
# Paso 1: ¿qué dice el proyecto de dispositivos? (la web esta tras un anti-bots; git si pasa)
git ls-remote https://gitlab.postmarketos.org/postmarketOS/pmaports.git HEAD
mkdir /tmp/pmaports-spes && cd /tmp/pmaports-spes && git init -q . && git remote add o https://gitlab.postmarketos.org/postmarketOS/pmaports.git
git config core.sparseCheckout true && printf 'device/*/device-xiaomi-spes/\ndevice/*/linux-xiaomi-spes/\n' > .git/info/sparse-checkout
git fetch -q --depth 1 o HEAD && git checkout -q FETCH_HEAD && find device -type f          # device/archived/...
cat device/archived/device-xiaomi-spes/{APKBUILD,deviceinfo}
grep "idVendor" device/archived/device-xiaomi-spes/deviceinfo | xxd                          # 0x05 d1 81 36: la "c" es U+0441

# Paso 2: ¿que variante es MI telefono? (con root)
adb shell 'su -c "od -An -tx1 /sys/firmware/devicetree/base/qcom,board-id"'                 # 00 04 00 22 -> spes-sm5602
adb shell getprop ro.product.model                                                          # 2201117TL

# Paso 3: mapa de particiones (solo lectura), con el tamano calculado en la laptop
adb shell 'su -c "cd /dev/block/bootdevice/by-name; for n in *; do b=\$(basename \$(readlink -f \$n)); echo \$n \$b \$(cat /sys/class/block/\$b/size); done"'

# Paso 4: respaldo de lo que no vuelve con la ROM de fabrica (solo lectura, verificado por hash)
bash artifacts/respaldar-particiones.sh                                                      # 14 OK, fallos: 0
# Etapa 1, paso 1 (QEMU): tu propio PID 1 en un initramfs de 4 entradas
cat modulos/mi_init/mi_init.c                                   # escrito a mano: mount /proc, getpid(), uptime, version, reboot(RB_POWER_OFF)
bash modulos/mi_init/construir.sh                               # gcc -static (aarch64) + gen_init_cpio + gzip -> out-initramfs/mi_init.cpio.gz
timeout 40 qemu-system-aarch64 -machine virt -cpu cortex-a72 -m 1G -nographic -kernel out-rust/arch/arm64/boot/Image -initrd out-initramfs/mi_init.cpio.gz -append "console=ttyAMA0 panic=-1" -no-reboot < /dev/null > logs/14-qemu-mi-init.log 2>&1; echo $?
# Etapa 1, paso 2 (QEMU): tu PID 1 lanza y espera a un hijo (fork/exec/waitpid)
bash modulos/mi_init/construir.sh      # ahora compila mi_init y hijo, 5 entradas en el initramfs
timeout 40 qemu-system-aarch64 ... -initrd out-initramfs/mi_init.cpio.gz ... > logs/14-qemu-mi-init2.log 2>&1
# Etapa 1, paso 3: un Alpine real (minirootfs 3.24.3) con tu inittab y tu propio servicio
wget https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/aarch64/alpine-minirootfs-3.24.3-aarch64.tar.gz
echo "4d3f80afaebd447c5591a63a73bde380a149fe8b2d85488cafabb2ff97551f50  alpine-minirootfs-3.24.3-aarch64.tar.gz" | sha256sum -c     # OK
mkdir -p src/alpine-rootfs && tar -xzf downloads/alpine-minirootfs-3.24.3-aarch64.tar.gz -C src/alpine-rootfs --no-same-owner
bash modulos/mi_alpine/construir.sh    # carpeta + overlay -> gen_initramfs.sh -u squash -g squash -> out-initramfs/mi_alpine.cpio.gz
timeout 60 qemu-system-aarch64 -machine virt -cpu cortex-a72 -m 1G -nographic -kernel out-rust/arch/arm64/boot/Image -initrd out-initramfs/mi_alpine.cpio.gz -append "console=ttyAMA0 panic=-1 lab=auto" -no-reboot < /dev/null > logs/14-qemu-alpine.log 2>&1
sed -n '/=== prueba automatica/,/=== fin/p' logs/14-qemu-alpine.log
# Etapa 1, paso 4 (QEMU con red): instalar un paquete de verdad con apk
bash modulos/mi_alpine/construir.sh    # incluye usr/local/bin/prueba-red (se activa con lab=red)
timeout 150 qemu-system-aarch64 -machine virt -cpu cortex-a72 -m 1G -nographic -kernel out-rust/arch/arm64/boot/Image -initrd out-initramfs/mi_alpine.cpio.gz -nic user,model=virtio-net-pci -append "console=ttyAMA0 panic=-1 lab=red" -no-reboot < /dev/null > logs/14-qemu-red.log 2>&1
sed -n '/=== prueba de red/,/=== fin/p' logs/14-qemu-red.log
# Etapa 1, paso 5 (QEMU con red): tu servicio como servicio de OpenRC, supervisado
#   modulos/mi_alpine/overlay/etc/init.d/mi-latido  (#!/sbin/openrc-run, supervisor="supervise-daemon", need localmount)
#   modulos/mi_alpine/overlay/usr/local/bin/mi-latido  (un latido por segundo, no termina nunca)
bash modulos/mi_alpine/construir.sh
timeout 150 qemu-system-aarch64 -machine virt -cpu cortex-a72 -m 1G -nographic -kernel out-rust/arch/arm64/boot/Image -initrd out-initramfs/mi_alpine.cpio.gz -nic user,model=virtio-net-pci -append "console=ttyAMA0 panic=-1 lab=red" -no-reboot < /dev/null > logs/14-qemu-openrc.log 2>&1
sed -n '/--- servicio de OpenRC/,/=== fin/p' logs/14-qemu-openrc.log
```

## Hallazgos reales

1. **La búsqueda web estaba desactualizada.** Decía que el paquete `device-xiaomi-spes` de postmarketOS estaba en `testing`. El repositorio real (`pmaports`, commit `c7940da`, 23-oct-2026) lo tiene en **`device/archived/`**, y el `APKBUILD` de dispositivo y de kernel empiezan con **`# Archived: unmaintained`** y `maintainer=""`: archivado y sin mantenedor.
2. **postmarketOS ahora se llama «Nura»** (cambio anunciado en septiembre de 2026; sitio nuevo `nura.eco`). Las páginas oficiales antiguas redirigían a ese dominio y **no se siguió el redirect hasta confirmarlo con fuentes independientes** (Notebookcheck, Linuxiac, It's FOSS). Las referencias a «postmarketOS» persisten en paquetes y documentación.
3. **Las webs del proyecto están tras un anti-bots (Anubis)** que bloquea a las herramientas automáticas (`Making sure you're not a bot!`), y la página de paquetes daba error 500. **`git` sí pasa**: `git ls-remote` devolvió el commit, y un clon **superficial y parcial** (`sparse-checkout`, `--depth 1`) trajo solo los archivos de `spes`.
4. **El paquete archivado es de kernel de fabricante.** `linux-xiaomi-spes` 4.19.325 construido de un fork personal de GitHub (`muralivijay/kernel_xiaomi_spes`, commit `ae003d9a…`) con la configuración de `spes-perf_defconfig`; `device-xiaomi-spes` usa `fastboot`, cabecera de `boot.img` **versión 3** y `postmarketos-base-downstream`. Es de la misma familia que el kernel 4.19 que ya compilaste (el tuyo es PixelExperience 4.19.297).
5. **Un typo real en el paquete archivado:** `deviceinfo_usb_idVendor="0x05с6"` lleva una **«с» cirílica (U+0441, bytes `d1 81`)** en lugar de la `c` ASCII del identificador USB de Qualcomm (`0x05c6`). Se vio porque `xxd` mostró dos bytes donde debía haber uno; lo mismo que `ñ` en el módulo 11.
6. **La página del dispositivo en la wiki** (que pegó el usuario; está traducida por máquina y **perdió algunas etiquetas de la tabla**, así que solo se citan las que se leen con claridad): «probado con Nura, pero su paquete aún no se ha añadido a los repositorios» (no se puede elegir en `pmbootstrap`), categoría «pruebas», kernel principal **7.2.9**, con Phosh funcionando. **Funciona:** pantalla táctil, aceleración 3D (Adreno 610), Wi-Fi, Bluetooth, háptica y el módem (**llamadas, SMS y datos móviles**). **Parcial:** cámara. **Roto:** flash de cámara, infrarrojo y sensor de proximidad. **Sin aclarar por la traducción:** GPS y otros sensores. **Audio «realmente malo»:** solo el altavoz inferior y un canal auxiliar, entrecortado y con ruido. El kernel principal está en `gitlab.postmarketos.org/sm6225-mainline/kernels/linux-v.7.2.1`. Un usuario de la lista usa **/e/OS a diario y Linux en una segunda partición**.
7. **Instalación según la página (vía kernel 4.19):** `pmbootstrap export`, desempaquetar el `boot.img`, **cambiar la cabecera de versión 0 a 3**, reempaquetar, **`fastboot flash boot`**, y **`pmbootstrap flasher flash_rootfs`**. Es la primera vez en el curso que aparece `flash` en lugar de `fastboot boot`. **No se verificó a qué partición va el sistema de archivos por defecto ni si Android sigue arrancando después.**
8. **Tres variantes del Redmi Note 11, y la tuya es la mejor soportada.** La página las distingue por `qcom,board-id`: `0002 0022` (MAX77729), `0003 0022` (`spesn`, NFC), `0004 0022` (`spes-sm5602`). El teléfono tiene **`00 04 00 22`** = `spes-sm5602`, modelo `2201117TL` (está en la lista de la página). El `dmesg` lo confirma: **3 307 menciones de `sm5602`**, cargador `nopmi_chg` y `sc8551`, y `st21nfc_dev_init: not supports NFC`. La desarrolladora del puerto principal dice poder probar solo las variantes SM5602 y no la de MAX77729.
9. **Mapa de particiones** (95 entradas, A/B para `boot`, `vendor_boot`, `modem`, `dsp`, `vbmeta`, `dtbo`...). **`userdata` = 102,3 GiB** (Android y, normalmente, el sistema de Linux), **`super` = 8,5 GiB** (`system`, `vendor`, `product`), `cust` = 2 GiB, `persist` = 32 MiB. **Error del mentor:** la primera lista salió con tamaños **negativos** (`userdata -1780 MiB`) porque el `sh` de Android calcula con 32 bits; se repitió pasando los sectores crudos y calculando en la laptop.
10. **Respaldo de lo que no vuelve con la ROM de fábrica.** `artifacts/respaldar-particiones.sh` copia con `dd` (`adb exec-out`, binario sin alterar) 14 particiones propias del teléfono a `backup/particiones/` (63 MiB), y **solo acepta cada copia si el SHA-256 y el tamaño coinciden entre el teléfono y la laptop**: **14 `OK`, `fallos: 0`**. Contenido real: `modemst1`, `modemst2` y `fsg` al 99,6 % de bytes no nulos, `persist` al 2,8 %; el resto está casi vacío (menos de un 0,1 %), coherente con un teléfono restablecido de fábrica. **Esas copias contienen datos personales del teléfono (IMEI, MAC, calibraciones): `backup/` está ignorado por Git y el script se niega a ejecutarse si no lo estuviera. Solo se versiona `logs/14-hash-particiones.txt` (nombres y hashes).**
11. **Veredicto de compatibilidad.** **Apto, con límites.** A favor: bootloader desbloqueado, `boot.img` v3, `fastboot`, variante bien soportada, el módem funciona. En contra: el paquete oficial está **archivado**, el nuevo **aún no está en los repositorios**, no hay buen audio ni cámara completa, y la instalación **escribe** en el teléfono. Como teléfono de uso diario es flojo; como equipo de laboratorio, razonable.

12. **Tu propio PID 1 arranca un sistema operativo de 273 KiB.** `mi_init.c` (31 líneas, escrito a mano, idéntico al dictado y sin avisos con `-Wall -Wextra`) se compila como binario **estático** de ARM64 (597 920 bytes sin símbolos) y se empaqueta con `gen_init_cpio` en un `initramfs` de **cuatro entradas** (`dev`, `dev/console`, `proc`, `init`) comprimido a **279 541 bytes**. Un nodo `/dev/console` es necesario para que el `printf` del PID 1 tenga salida, y normalmente crear un nodo exige root; `gen_init_cpio` lo describe en un archivo de texto (`modulos/mi_init/initramfs.lista`) sin necesitarlo.
13. **Resultado en QEMU** (`logs/14-qemu-mi-init.log`, el mismo kernel 6.18.58 del módulo 11): `[0.781737] Run /init as init process`, **`mi_init: hola, soy el PID 1`**, `/proc/uptime: 0.80 0.00`, `/proc/version: Linux version 6.18.58 …`, `mi_init: apagando`, y **código de salida de QEMU 0** (apagado limpio por `reboot(RB_POWER_OFF)`; 124 habría significado que se agotó el `timeout`). **Sin pánico**, a diferencia del módulo 11. El segundo valor de `/proc/uptime` (CPU inactiva acumulada) es 0,00: en 0,8 s el procesador no tuvo ningún instante libre. Un PID 1 que simplemente terminara habría provocado un pánico del kernel, por eso termina apagando la máquina.

14. **Tu PID 1 lanza y espera a un hijo.** Con `fork`/`execl`/`waitpid` (`mi_init.c` + `hijo.c`; ambos compilan sin avisos con `-Wall -Wextra`): `hijo: soy el PID 53 y mi padre es el PID 1`, `mi_init: el hijo 53 termino con codigo 7`, apagado limpio (código de QEMU 0). **El hijo es el PID 53 y no el 2** porque los PID 2 a 52 los ocupan hilos del propio kernel creados antes de `/init`. El `return 7` de `hijo.c` llega hasta `WEXITSTATUS` en el padre: es lo que usa todo gestor de servicios para saber si algo acabó bien o mal.
15. **La imagen mínima de Alpine no trae OpenRC, aunque su `inittab` lo invoque.** `alpine-minirootfs-3.24.3-aarch64.tar.gz` (4 029 999 bytes, SHA-256 `4d3f80af…1f50` verificado: `OK`; el hash se leyó del mismo servidor de Alpine, así que prueba integridad y no autenticidad, y la firma PGP no se verificó) desempaquetada son 8,9 MB y 515 archivos, **16 paquetes** (`busybox`, `musl`, `apk-tools`, `alpine-baselayout`...) y **ni `/sbin/openrc` ni `/etc/init.d`**; `/sbin/init` es un enlace a `/bin/busybox` (dinámico, con musl). Por eso se usa el `init` de BusyBox con un `inittab` propio, y OpenRC quedaría para instalarlo después con `apk`.
16. **`inittab` propio y servicio propio** (`modulos/mi_alpine/overlay/`): `sysinit` monta `/proc`, `/sys` y `/dev` (devtmpfs) y pone el nombre `fabian-lab`; `respawn` supervisa `mi-servicio` (da 3 latidos y termina) y una consola serie; `once` ejecuta `arranque`, que solo actúa si el kernel recibió `lab=auto`. `gen_initramfs.sh -u squash -g squash` deja todo como root sin ser root, y `extras.lista` aporta `/dev/console` y el enlace `/init -> /sbin/init`. **Error del mentor:** se supuso que `gen_initramfs.sh` buscaba `gen_init_cpio` junto a sí mismo; falló con `usr/gen_init_cpio: not found` porque lo busca con **ruta relativa** a la carpeta de ejecución, y se corrigió ejecutándolo desde `out-rust/`. Resultado: **4 028 819 bytes, 519 entradas**.
17. **Resultado en QEMU** (`logs/14-qemu-alpine.log`): `Linux 6.18.58`, `hostname: fabian-lab`, `uptime: 9.22s`, `Alpine 3.24.3`, apagado limpio (código 0). `ps`: `1 /init` y `2 [kthreadd]` son los únicos sin padre; todos los `[kworker/…]`, `[rcu_preempt]`, `[kswapd0]`... cuelgan del PID 2; de usuario solo `57 {arranque}` y `58 sleep 100000` (padre 1). **El servicio fue supervisado:** `1.16s PID 59 latido 1,2,3` → `5.24s PID 69 latido 1,2,3` → `9.32s PID 82 latido 1`: tres PID distintos para el mismo servicio. Entre una vida y la siguiente pasa **cerca de 1 s** (medido en el registro; no se comprobó si es una espera deliberada de BusyBox). Su ausencia en el `ps` (ejecutado a los ~9,2 s) se debe a que la tercera vida aún no había arrancado.

18. **El kernel de QEMU ya tenía todo lo necesario para la red:** `VIRTIO_NET=y`, `VIRTIO_PCI=y`, `NET`, `INET`, `PACKET`, y también `NAMESPACES` (`PID_NS`, `NET_NS`, `USER_NS`, `UTS_NS`, `IPC_NS`) y `CGROUPS` (`MEMCG`, `CGROUP_PIDS`) para el punto de seguridad de la guía. Corrección del mentor: un `ls … | awk` de `resolv.conf` y `network/interfaces` imprimió «existe el archivo» y parecía que existían; era el mensaje de error («No existe el archivo…») partido por `awk`. **Ninguno de los dos existía**; no hizo falta crearlos porque `udhcpc` genera `resolv.conf` con su `default.script`.
19. **Red y paquetes en QEMU** (`logs/14-qemu-red.log`, `-nic user,model=virtio-net-pci`, `lab=red`): `eth0` (virtio-net) aparece y se levanta; **DHCP** `lease of 10.0.2.15 obtained from 10.0.2.2` (`10.0.2.15/24`, ruta por defecto vía `10.0.2.2`); `nameserver 10.0.2.3`; `apk update` sobre `https://dl-cdn.alpinelinux.org/alpine/v3.24/{main,community}` → **28 570 paquetes disponibles** (`v3.24.3-39-g7e71067f4e8` y `v3.24.3-38-gc3f47567305`). `apk add openrc` instaló **5 paquetes** (`bridge 1.5-r5`, `ifupdown-ng 0.13.0-r0`, `openrc-user`, `libcap2 2.78-r0`, `openrc 0.63.2-r0`): de 16 a **21 paquetes, 12,8 MiB**; `/sbin/openrc` pasó de «No such file or directory» a `-rwxr-xr-x 67440`. Apagado limpio (código de QEMU 0). La descarga fue por HTTPS y no se usó `--allow-untrusted`, así que `apk` aplicó su verificación de firmas normal con las claves de `alpine-keys`; la verificación no se imprime en la salida, solo se infiere de que no se usó la opción para saltarla.
20. **Error del mentor en la propia prueba:** la línea `version de openrc` imprimió la descripción («OpenRC manages the services, startup and shutdown of a host») en lugar del número, porque en `apk` 3 la opción `-v` es «detallado» y muestra la descripción; la versión real es `0.63.2-r0`, visible en la instalación. **Limitación:** el paquete se instaló solo en la memoria de esta ejecución (el `initramfs` vive en RAM); al apagar se pierde. Para conservarlo habría que reconstruir el `initramfs` con los archivos ya instalados o usar un disco.

21. **Un servicio propio de OpenRC, arrancado y supervisado** (`logs/14-qemu-openrc.log`). Se escribió `/etc/init.d/mi-latido` (`#!/sbin/openrc-run`, `supervisor="supervise-daemon"`, `need localmount`) y `usr/local/bin/mi-latido`. `rc-service mi-latido start` imprimió `Remounting filesystems … [ ok ]`, `Mounting local filesystems … [ ok ]` y `Starting mi-latido … [ ok ]`: las dos primeras no las escribió el autor, vienen de **resolver la dependencia `need localmount`** (OpenRC arrancó antes el servicio del que dependía el suyo). `status: started`. Árbol de procesos: `336 1 supervise-daemon mi-latido --start --pidfile /run/mi-latido.pid --respawn-delay 2 --respawn-max 5 --respawn-period 1800 …` (PID 336, hijo del PID 1) y `338 336 {mi-latido} /bin/sh /usr/local/bin/mi-latido` (PID 338, hijo del supervisor). **Relanzamiento:** matado el hijo 338 con `kill -9`, el supervisor 336 lanzó el **PID 392** (`26.10s PID 338 latido 5` → `28.51s PID 392 latido 1`, 2,4 s después, coherente con `respawn-delay 2`; inferencia, no medición del supervisor). `rc-service mi-latido stop` → `Stopping mi-latido … [ ok ]`, `status: stopped`; apagado limpio (código 0). **Diferencia con el `respawn` de BusyBox:** `supervise-daemon` limita a **5 relanzamientos cada 1 800 s** por defecto; un servicio que se cae en bucle acaba rindiéndose.
22. **Errores del mentor en esta prueba.** (a) El primer `grep` para elegir a quién matar (`"[m]i-latido$"` con `awk 'NR==1'`) habría escogido al supervisor, porque `supervise-daemon` también termina su línea de comandos en `mi-latido` y tiene un PID menor: se detectó **antes** de ejecutar leyendo la salida de `ps` anterior y se cambió por `"[/]bin/sh /usr/local/bin/mi-latido"`. (b) `rc-service mi-latido describe` imprimió `reload: no description` en lugar del texto de `description=`; no se investigó. (c) Se preparó a mano `/run/openrc/softlevel` sin saber si OpenRC lo necesitaba sin haber ejecutado su arranque completo; **funcionó**, pero no se comprobó que fuera imprescindible.

## Evidencias

![Respaldo de 14 particiones con verificación](evidencias/01-respaldo-de-particiones.png)

**02 — Tu PID 1 en QEMU (hallazgos #12 y #13)**
`Run /init as init process`, `mi_init: hola, soy el PID 1`, `/proc/uptime`, `/proc/version` y `mi_init: apagando`; código de salida 0.
![mi_init en QEMU](evidencias/02-qemu-mi-init-pid-1.png)

**03 — Tu PID 1 con un hijo (hallazgo #14)**
`hijo: soy el PID 53 y mi padre es el PID 1`, `el hijo 53 termino con codigo 7`.
![hijo y padre](evidencias/03-qemu-mi-init-con-hijo.png)

**04 — Descarga y verificación de Alpine (hallazgo #15)**
`alpine-minirootfs-3.24.3-aarch64.tar.gz: OK`.
![descarga de Alpine](evidencias/04-descarga-alpine-minirootfs-sha256.png)

**05 y 06 — Alpine arrancado en QEMU con tu inittab (hallazgo #17)**
Tabla de procesos (`kthreadd` como PID 2, `{arranque}` y `sleep` como únicos de usuario) y los latidos de `mi-servicio` con tres PID distintos.
![procesos 1](evidencias/05-qemu-alpine-procesos-parte-1.png)
![procesos 2 y latidos](evidencias/06-qemu-alpine-procesos-y-latidos.png)

**07 y 08 — Red y paquetes en QEMU (hallazgo #19)**
DHCP, DNS, `apk update` (28 570 paquetes) y `apk add openrc` (5 paquetes, 12,8 MiB; `/sbin/openrc` aparece).
![DHCP y apk update](evidencias/07-qemu-red-dhcp-apk-update.png)
![apk add openrc](evidencias/08-qemu-red-apk-add-openrc.png)

**09 y 10 — Tu servicio en OpenRC (hallazgo #21)**
Arranque con dependencia resuelta, árbol de procesos con el supervisor `supervise-daemon`, el hijo matado y relanzado con otro PID, y la parada.
![servicio arrancado](evidencias/09-openrc-servicio-arrancado-y-supervisado.png)
![servicio relanzado y parado](evidencias/10-openrc-relanzado-y-parado.png)

Registros: `logs/14-hash-particiones.txt` (SHA-256 de las 14 copias; las copias en sí no se publican) y `artifacts/respaldar-particiones.sh`. La página de la wiki del dispositivo (`wiki.nura.eco/wiki/Xiaomi_Redmi_Note_11_(xiaomi-spes)`) se consultó en el navegador del usuario porque la herramienta automática estaba bloqueada.

## Pendientes

- [x] Compatibilidad: estado del puerto, variante propia, mapa de particiones y veredicto.
- [x] Respaldo de las particiones propias del teléfono, verificado por hash.
- [x] Etapa 1, paso 1 (QEMU): *initramfs* mínimo con **PID 1 propio** (`mi_init`), arranque y apagado limpios.
- [x] Etapa 1, pasos 2 y 3: PID 1 con `fork`/`exec`/`wait`, y un Alpine real con tu `inittab` y un servicio propio supervisado.
- [x] Etapa 1, paso 4: red en QEMU (DHCP, DNS) y `apk add openrc` dentro del sistema.
- [x] Etapa 1, paso 5: tu servicio como servicio de OpenRC, con dependencia, supervisión y relanzamiento comprobados.
- [ ] Etapa 1, siguientes pasos: empaquetar un programa propio como paquete de Alpine (`apk`) o Debian (`.deb`); usuarios, permisos, *namespaces* y *cgroups*; Wayland/Phosh (opcional).
- [ ] **Etapa 3, en el teléfono sin escribir nada:** `fastboot boot` con el kernel propio y un `initramfs` propio, para tener Linux sin Android sin flashear.
- [ ] **Etapa 4, solo con confirmación explícita del usuario:** `fastboot flash`. Antes verificar a qué partición va el *rootfs*, si Android sigue arrancando, y hacer una copia fuera de la laptop de `backup/particiones/`.
- [ ] Verificar la firma PGP del kernel 6.18.58 (pendiente del módulo 11).
