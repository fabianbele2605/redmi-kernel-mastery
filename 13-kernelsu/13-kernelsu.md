# Módulo 13 — KernelSU (opcional)

- Estado: En progreso
- Fecha: 2026-10-23
- Kernel: `4.19.297-uvite` (`src/kernel-px`, rama `lab/ksu-01-integracion`, parte de `lab/cambio-02-kernel-init`)
- KernelSU: **v0.9.5**, commit `b766b98513b5a7eb33bc1c4a76b5702bf1288f07` (29-may-2024), clonado en `src/ksu-official` (ignorado por Git)
- Objetivo: tener root/observación en vivo en el teléfono de laboratorio (aislado, sin cuentas ni apps personales), integrando KernelSU **a mano** en un kernel 4.19 que no es GKI, con cada cambio en su propio commit.

## Concepto

KernelSU concede root desde dentro del kernel: un módulo del propio kernel decide qué aplicaciones pueden ejecutar `su`. Lo hace en dos mitades: (1) una parte que **vigila** (a través de los *hooks* de seguridad del kernel, LSM) cuándo cambia la lista de aplicaciones y busca la **app gestora oficial** comparando su firma con la fijada al compilar; (2) una parte que **concede el root**, que necesita *ganchos* en funciones del kernel (`do_execveat_common`, `do_faccessat`, `vfs_read`, `vfs_statx`, `input_handle_event`). En kernels GKI esos ganchos usan `kprobes`; en uno 4.19 no GKI se pueden usar `kprobes` o insertarlos a mano en el código fuente (vía manual, con `CONFIG_KPROBES` apagado).

**Riesgo asumido:** root total sobre el teléfono. Solo se hace en un teléfono de laboratorio, sin cuentas personales ni apps bancarias.

## Práctica guiada

```bash
# Paso 0: traer el código desde otra red (esta bloquea GitHub) y fijarlo a v0.9.5; NO se ejecuta setup.sh
cd ~/Escritorio/Mobil/src && git clone https://github.com/tiann/KernelSU.git ksu-official
cd ksu-official && git checkout v0.9.5 && git log -1 --format='%H%n%an%n%ad%n%s'

# Paso 1: integración a mano (las 3 piezas que haría setup.sh), rama aparte, sin ganchos
cd ~/Escritorio/Mobil/src/kernel-px && git checkout -b lab/ksu-01-integracion
ln -s ../../ksu-official/kernel drivers/kernelsu
#   drivers/Kconfig:  source "drivers/kernelsu/Kconfig"      (antes del endmenu)
#   drivers/Makefile: obj-$(CONFIG_KSU) += kernelsu/
git add drivers/Kconfig drivers/Makefile drivers/kernelsu && git commit -m "lab: integrar KernelSU v0.9.5 en drivers/kernelsu (sin ganchos)"   # 89acccabe
cd ~/Escritorio/Mobil && source artifacts/entorno-px.sh
src/kernel-px/scripts/config --file out-px/.config -e KSU
kmake olddefconfig 2>&1 | grep -v "unsupported character" | tail -3; grep -n "CONFIG_KSU" out-px/.config     # CONFIG_KSU=y
time kmake -j12 2>&1 | tee logs/13-build-ksu01.log | tail -8                                                     # real 34,3 s
cp out-px/arch/arm64/boot/Image.gz artifacts/px/Image-ksu01.gz
python3 tools/mkbootimg/mkbootimg.py --header_version 3 --os_version 12.0.0 --os_patch_level 2023-12 --kernel artifacts/px/Image-ksu01.gz --ramdisk backup/stock-unpacked/boot/ramdisk --cmdline 'ramoops_memreserve=4M' -o artifacts/px/boot-lab-ksu01.img
sha256sum artifacts/px/boot-lab-ksu01.img | tee logs/13-hash-boot-lab-ksu01.txt
adb reboot bootloader && fastboot boot artifacts/px/boot-lab-ksu01.img
adb shell 'su -c id'                                        # su: inaccessible or not found (esperado)
bash artifacts/capturar-dmesg.sh ksu01                      # logs/08-dmesg-ksu01.txt
grep -n -i "kernelsu" logs/08-dmesg-ksu01.txt | head
```

## Hallazgos reales

1. **KernelSU oficial ya no da soporte a kernels no GKI.** Su guía (archivada) dice que desde la v1.0 se dejó de soportar y que la última versión que lo hacía es la **v0.9.5**. Para 4.19 no hay tutorial oficial: lo más detallado está en forks de terceros, que se descartaron por ser código ajeno con acceso a root.
2. **Esta red bloqueaba GitHub** (`ssl_verify=20` en `curl`, el mismo cortafuegos que bloqueaba el `git push`); no se desactivó la verificación de certificados. El código se descargó desde otra red (`github.com` → `HTTP 200`, `ssl_verify=0`).
3. **La etiqueta `v0.9.5` es ligera** (apunta a un commit, no está firmada: `cannot verify a non-tag object of type commit`) y su último commit es un arreglo de un typo de la web, lo cual extrañó. Se comprobó con las fechas: `v0.9.4` 9-may, **`v0.9.5` 29-may**, `v1.0.0` 1-jun-2024, y los últimos cambios dentro de `kernel/` son del 26-27 de mayo. Coherente.
4. **`setup.sh` leído línea a línea antes de usarlo, y no se ejecutó.** Hace solo: `git clone`/`git pull` del repositorio dentro del árbol, enlace simbólico `drivers/kernelsu`, la línea `obj-$(CONFIG_KSU) += kernelsu/` en `drivers/Makefile` y `source "drivers/kernelsu/Kconfig"` antes del `endmenu` de `drivers/Kconfig`. Se reprodujeron las tres piezas a mano.
5. **Revisión del código del kernel de KernelSU** (5 521 líneas en `kernel/`): sin `socket`, `kernel_connect`, `call_usermodehelper` ni accesos a red (las coincidencias con `http` eran comentarios). El root solo se concede a la app cuya firma coincide con `KSU_EXPECTED_SIZE := 0x033b` y `KSU_EXPECTED_HASH := c371061b19d8c7d7d6133c6a9bafe198fa944e50c1b31c9d8daa8d7f1fc2d2d6` (el `Makefile` del módulo) y a las apps que ese gestor autorice.
6. **Estado de tu kernel frente a la vía manual:** las seis funciones de los ganchos existen (`do_execveat_common`, `do_faccessat`, `vfs_read`, `vfs_statx`, `input_handle_event`, `devpts_get_priv`); falta `path_umount` (backport de la 5.9, solo para «desmontar módulos», opcional). `CONFIG_KPROBES` no estaba activado (solo `HAVE_KPROBES=y`), que es lo correcto para la vía manual. `CONFIG_OVERLAY_FS=y`, que `Kconfig` de KernelSU exige. Ningún gancho de KernelSU en el árbol de partida.
7. **Integración (paso 1): commit `89acccabe`, 3 archivos, 4 líneas** (`create mode 120000 drivers/kernelsu`). Compila **sin errores ni avisos** a la primera: 34,3 s, 12 archivos en `drivers/kernelsu/` (`ksu.o`, `core_hook.o`, `sucompat.o`, `apk_sign.o`, `throne_tracker.o`...), **82 símbolos `ksu_…`** en `vmlinux` y la firma del gestor impresa en el registro. Un primer recuento con `grep ksu` dio 170 símbolos y era falso (coincidía con `ch**ksu**m`).
8. **Con KernelSU dentro y sin ganchos, el teléfono arranca normal y no hay root** (`su: inaccessible or not found`). `boot-lab-ksu01.img`, SHA-256 `167bf1a0e9b4bb3fb09618c85b0b2e3986121838cb2f3066913042493186b686`; `fastboot boot` `OKAY [0.869s]` / `OKAY [0.318s]`; arrancó con `4.19.297-uvite`.
9. **Aun sin ganchos, KernelSU ya funciona a medias.** En el `dmesg`: `[2.001963] KernelSU: KPROBES is disabled, KernelSU may not work…` y, a los 14 s, `renameat: packages.list.tmp -> packages.list`, `Searching manager...` y 94 líneas `Found new base.apk at path: …, is_manager: 0`. La parte que **vigila** funciona por los *hooks* de seguridad (LSM), sin `kprobes` ni ganchos manuales; la que **concede root** (`su`) no. Ninguna app es el gestor (`is_manager: 0`), como corresponde.
10. **Fuga que el mentor casi deja pasar:** KernelSU imprime la ruta de cada app y **87 de esas líneas llevaban carpetas aleatorias propias del teléfono** (`/data/app/~~<aleatorio>==/<paquete>-<aleatorio>==/base.apk`). Se añadió al extractor una regla que las cambia por `[APP-TAPADA]` y a la prueba de fugas el contador `APPS`; el registro se regeneró desde su `.zip` (0 rutas `~~` restantes, 87 tapadas) **antes** de versionarlo. Los ocho registros anteriores tenían 0 de esas rutas.
11. **Limitación conocida de privacidad (no corregida):** los mensajes de SELinux (`avc: granted/denied`) citan rutas como `/data/data/com.facebook.katana/…` (paquetes comunes, aquí preinstalados en la ROM). Aparecen también en los registros ya publicados (4 a 13 líneas cada uno). Tapar esos nombres exigiría reescribir lo publicado.

## Evidencias

Este módulo se documenta con los registros guardados:
- `logs/13-build-ksu01.log` — compilación con KernelSU integrado, sin ganchos.
- `logs/13-hash-boot-lab-ksu01.txt` — SHA-256 de la imagen probada.
- `logs/08-dmesg-ksu01.txt` — `dmesg` del arranque (línea 835: `KPROBES is disabled`; líneas 3539 en adelante: `Searching manager...`).

## Pendientes

- [x] Paso 0: código de KernelSU v0.9.5 descargado y fijado; `setup.sh` leído.
- [x] Paso 1: integración sin ganchos, compilada, arrancada, sin root (esperado).
- [ ] Paso 2: los ganchos manuales, **uno por commit**: `fs/exec.c`, `fs/open.c`, `fs/read_write.c`, `fs/stat.c`, `drivers/input/input.c` (y `fs/devpts/inode.c` si hace falta).
- [ ] Paso 3: instalar la app gestora oficial v0.9.5 **comprobando antes que su firma coincide** con `0x033b` / `c371061b…`.
- [ ] Paso 4: aprovechar el root: `insmod` de `hello_lab.ko`, leer `/proc/hello_lab`, y el paso 6 diferido del módulo 12 (`drop_caches`).
- [ ] Probar la reversibilidad de cada gancho con `git revert`.
