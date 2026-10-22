# Módulo 8 — Depuración: ver lo que dice el kernel

- Estado: En progreso
- Fecha: 2026-10-22
- Teléfono: Redmi Note 11 `spes`, ROM `user` (Android 13, MIUI `V14.0.5.0.TGCMIXM`), bootloader desbloqueado, kernel de fábrica en marcha (`4.19.157-perf-gcb1ffc010755`)
- Objetivo: poder **leer el registro del kernel** (`dmesg`) y el del arranque anterior (`pstore`) en una ROM de usuario sin root, para saber qué dice el kernel cuando algo falla. Es la base del Módulo 9 (`printk` de tu propio módulo).

## Concepto

El kernel escribe sus mensajes (`printk`) en un **búfer circular** en memoria. `dmesg` lo lee. En una ROM `user` el usuario `shell` de `adb` no puede (`klogctl: Permission denied`). Hay tres vías:

1. **`adb bugreport`**: el sistema vuelca, con privilegios propios, el `dmesg` dentro de un `.zip`. No necesita root. Contiene también datos personales, así que **el `.zip` nunca va a Git**.
2. **`pstore`/`ramoops`**: parte de la RAM se reserva y el kernel guarda ahí su consola y los *panics*; **sobrevive a un reinicio**. Es la única forma de ver *por qué* se reinició un kernel que falló. En el siguiente arranque se lee en `/sys/fs/pstore` o `/proc/last_kmsg` (en esta ROM, solo `system`/`log`).
3. **Consola serie** (UART): ver los mensajes en directo desde el arranque; necesita hardware y soporte de kernel.

## Datos de partida (comprobados antes de empezar)

- `logcat -b kernel` no da nada (0 líneas); `/sys/fs/pstore` es `dr-xr-x--- system log` (`Permission denied` para `shell`); `/proc/last_kmsg` existe pero con permisos `-r--r-----`; `bugreportz` existe.
- Kernel de fábrica: `CONFIG_PSTORE=y`, `PSTORE_CONSOLE=y`, `PSTORE_PMSG=y`, `PSTORE_RAM=y`, `PRINTK_TIME=y`, `LOG_BUF_SHIFT=21` (búfer de 2 MiB), `MAGIC_SYSRQ=y`, `# SERIAL_MSM_GENI_EARLY_CONSOLE is not set`, `# DYNAMIC_DEBUG is not set`.
- El DT de PixelExperience reserva `ramoops@5D000000` (4 MiB: `record-size` 0x80000, `console-size` 0x100000, `pmsg-size` 0x200000). **[VERIFICAR]** que el DTB de fábrica de `vendor_boot` (el que usa el teléfono) también lo reserva.
- La línea de comandos de fábrica trae `earlycon=msm_geni_serial,0x4a90000`, pero sin `SERIAL_MSM_GENI_EARLY_CONSOLE` esa consola temprana no tiene efecto. **[VERIFICAR]**

## Plan

| Paso | Qué | Toca el teléfono |
|---|---|---|
| 1 | `adb bugreport` con el kernel de fábrica (el `.zip` queda en `backup/`) | Solo lectura |
| 2 | Extraer **solo** `dmesg` y `LAST KMSG`, ya con serial/MAC tapados (`artifacts/extraer-dmesg.py`) | No |
| 3 | Leer ese `dmesg`: banner, línea de comandos real, inicio de `pstore`, errores | No |
| 4 | Repetirlo con tu kernel (`fastboot boot` temporal) y **comparar** | Arranque temporal |
| 5 | ¿Hay `ramoops` en el DTB de fábrica? (separar y descompilar el DTB de `vendor_boot`) | No |

## Práctica guiada

```bash
# Paso 1: informe de depuración (el .zip contiene datos personales: queda en backup/, que Git ignora)
adb devices
adb bugreport backup/bugreport-fabrica.zip
ls -lh backup/bugreport-fabrica.zip                       # 16M
unzip -l backup/bugreport-fabrica.zip | head -15          # solo lista, no extrae

# Paso 2: extraer SOLO el registro del kernel, con identificadores tapados
python3 artifacts/extraer-dmesg.py backup/bugreport-fabrica.zip logs/08-dmesg-fabrica.txt
wc -l logs/08-dmesg-fabrica.txt                           # 17398
grep -c "$(adb get-serialno)" logs/08-dmesg-fabrica.txt   # 0  (prueba de fugas)
sed -n 3,6p logs/08-dmesg-fabrica.txt | cut -c1-170
```

## Hallazgos reales

1. **Qué puede leer el usuario `shell` en una ROM `user` (comprobado):** `logcat -b kernel` → 0 líneas; `ls /sys/fs/pstore` → `Permission denied` (el directorio es `dr-xr-x--- system log`); `/proc/last_kmsg` → `-r--r----- system log`; ya sabíamos que `dmesg`, `/proc/cmdline`, `/proc/bus/input/devices` y `/proc/asound/cards` dan `Permission denied`. Sí existe `/system/bin/bugreportz`.
2. **`SERIAL_MSM_GENI_EARLY_CONSOLE` está apagado en el kernel de fábrica** (`# CONFIG_SERIAL_MSM_GENI_EARLY_CONSOLE is not set`), aunque la línea de comandos pide `earlycon=msm_geni_serial,0x4a90000`: esa consola temprana no tiene efecto. **[VERIFICAR]** cuando se lea el `dmesg`.
3. **El árbol de PixelExperience reserva memoria para `ramoops`** (`techpack`/`khaje.dtsi` línea 450): `ramoops@5D000000`, 4 MiB, `record-size 0x80000`, `console-size 0x100000`, `pmsg-size 0x200000`. El kernel de PX trae `PSTORE`; falta saber si el DTB de fábrica también lo reserva.
4. **`adb bugreport` funciona sin root:** copia **16 MB** en 0,45 s a `backup/bugreport-fabrica.zip`. El zip trae `version.txt`, `proto/*_CRITICAL.proto`, el `bugreport-spes_global-TKQ1.221114.001-….txt` y las carpetas de **MQSAS**, el sistema de estabilidad de MIUI (`FS/mnt/rescue/mqsas/stabilityrecord/LocalKernelExceptionRecord.txt`, `LocalHangRecord.txt`, `BootFailure/BootFailure_spes_V14.0.2.0…zip`, `UnhealthyBootLog/…`, `android-kmsg.txt` de 1,9 MB). Es material muy personal y de MIUI: **el zip nunca se abre ni se publica**; solo lo procesa el script.
5. **`artifacts/extraer-dmesg.py` extrae `KERNEL LOG (dmesg)` (17 396 líneas) y `LAST KMSG` (vacía: no hubo ningún *panic* previo) con los identificadores tapados.** Se probó contra el zip real y con una **prueba de fugas** (`grep -c "$(adb get-serialno)"` = 0). Al leer el resultado se vio que la línea de comandos incluía `androidboot.vbmeta.device=PARTUUID=5f899e57-…`, el **identificador único de una partición**, que el script no tapaba. Se añadieron `PARTUUID=` y los UUID genéricos y se regeneró; las pruebas dan 0 para serial, `PARTUUID`, UUID, números de 15 dígitos y MAC. Lección: **una prueba de fugas no basta con el serial; hay que leer el contenido y preguntarse qué más identifica al aparato.**
6. **Hay 11 090 líneas de nivel `ERR` (`<3>`) sobre 17 398, pero no son errores reales:** son los controladores de batería y carga de Xiaomi, que imprimen su estado con `pr_err`: `fg_read_temperature` y `_calculate_battery_temp_ex` (932 veces cada uno), `fg_read_current` (669), `fg_get_property` (469) y `nopmi_cv_step_monitor_work` (352 y 306). **El nivel lo elige el autor del controlador, no mide la gravedad real.** Por eso un `dmesg | grep err` en este teléfono es inútil si no se filtra primero esa charla. Distribución: `ALERT` 2, `ERR` 11 090, `WARN` 741, `NOTICE` 213, `INFO` 4 677, `DEBUG` 22.
7. **`pstore`/`ramoops` ya funciona en el kernel de fábrica y el DTB de fábrica sí reserva la memoria** (responde el **[VERIFICAR]** del plan): `ramoops: dump_mem_sz=1048576, record_size=524288, size=4194304, console_size=1048576, ftrace_size=0, pmsg_size=2097152`; `console [pstore-1] enabled`; `pstore: Registered ramoops as persistent store backend`; `ramoops: attached 0x400000@0x5d000000, ecc: 0/0`; `pstore: Using compression: deflate`. Es **la misma reserva** (`0x5d000000`, 4 MiB) que el DT de PixelExperience. Un *panic* de nuestro kernel dejará su rastro en `/sys/fs/pstore`, que `shell` no puede leer (hay que usar `LAST KMSG` del `bugreport` o root).
8. **La consola temprana de la línea de comandos no hace nada**, tal como se sospechaba: aunque `earlycon=msm_geni_serial,0x4a90000` está en la línea de comandos, el `dmesg` **no contiene ninguna línea `bootconsole` ni de `earlycon`** (coherente con `# CONFIG_SERIAL_MSM_GENI_EARLY_CONSOLE is not set`). Para ver el arranque por UART habría que activarla en nuestro kernel.
9. **La línea de comandos real del kernel** (ya sin identificadores) es la de `vendor_boot` más lo que añade el bootloader y el DT: `cgroup_disable=pressure rcupdate.rcu_expedited=1 rcu_nocbs=0-7 kpti=off console=ttyMSM0,115200n8 earlycon=msm_geni_serial,0x4a90000 androidboot.hardware=qcom … buildvariant=user androidboot.verifiedbootstate=orange androidboot.keymaster=1 androidboot.vbmeta.device=PARTUUID=[TAPADO] androidboot.vbmeta.avb_version=1.0 androidboot.vbmeta.device_state=unlocked androidboot.vbmeta.hash_alg=sha256 androidboot.vbmeta.size=7360 androidboot.vbmeta.digest=7ddb33b4… androidboot.vbmeta.invalidate_on_error=yes androidboot.veritymode=enforcing androidboot.bootdevice=4804000.ufshc androidboot.fstab_suffix=default androidboot.boot_devices=soc/4804000.ufshc androidboot.serialno=[TAPADO] androidboot.cpui`. **Termina cortada** en `androidboot.cpui`: el kernel limita la línea de comandos a un tamaño fijo, y el final (`androidboot.cpuid=…`) se perdió.
10. **SELinux registra 212 denegaciones (`avc: denied`) en 713 s de funcionamiento**, entre ellas la nuestra: a los 422 s, `comm="ls" name="/" dev="pstore" … scontext=u:r:shell:s0`, es decir, nuestro `ls /sys/fs/pstore` desde `adb shell` (hallazgo #1). Se ven también 754 mensajes de `binder`. El último registro del `dmesg` es el instante 713,5 s.

## Evidencias

**01 — Extracción del `dmesg` y prueba de fugas (hallazgos #5 y #6)**
`extraer-dmesg.py` produce `logs/08-dmesg-fabrica.txt` de 17 396 líneas (17 398 con `wc`), la prueba de fugas da `0` y se ven las primeras líneas (`Booting Linux`, `Linux version 4.19.157-perf-gcb1ffc010755`, `Machine model: … SPES KHAJE IDP nopmi`).
![Extracción del dmesg y prueba de fugas](evidencias/01-extraer-dmesg-y-prueba-de-fugas.png)

## Pendientes

- [x] Paso 1: `adb bugreport` con el kernel de fábrica (16 MB, en `backup/`).
- [x] Paso 2: `dmesg` y `LAST KMSG` extraídos y sin datos personales (`logs/08-dmesg-fabrica.txt`, prueba de fugas = 0).
- [x] Paso 3 (análisis del mentor): cmdline real, `pstore`/`ramoops` activo, `earlycon` inerte, charla de la batería a nivel ERR.
- [ ] Paso 3 (el usuario): repetir las búsquedas con `grep` en `logs/08-dmesg-fabrica.txt` para familiarizarse.
- [ ] Paso 4: `dmesg` con tu kernel y comparación.
- [x] Paso 5: ¿`ramoops` en el DTB de fábrica? **Sí**: `attached 0x400000@0x5d000000` (hallazgo #7). No hizo falta descompilar el DTB.
- [ ] (Módulo 13) Provocar un *panic* controlado y leerlo desde `pstore`: requiere root (`echo c > /proc/sysrq-trigger`).
