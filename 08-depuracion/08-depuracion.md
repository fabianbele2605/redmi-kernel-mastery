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
# se completa con los comandos reales ejecutados
```

## Hallazgos reales

1. **Qué puede leer el usuario `shell` en una ROM `user` (comprobado):** `logcat -b kernel` → 0 líneas; `ls /sys/fs/pstore` → `Permission denied` (el directorio es `dr-xr-x--- system log`); `/proc/last_kmsg` → `-r--r----- system log`; ya sabíamos que `dmesg`, `/proc/cmdline`, `/proc/bus/input/devices` y `/proc/asound/cards` dan `Permission denied`. Sí existe `/system/bin/bugreportz`.
2. **`SERIAL_MSM_GENI_EARLY_CONSOLE` está apagado en el kernel de fábrica** (`# CONFIG_SERIAL_MSM_GENI_EARLY_CONSOLE is not set`), aunque la línea de comandos pide `earlycon=msm_geni_serial,0x4a90000`: esa consola temprana no tiene efecto. **[VERIFICAR]** cuando se lea el `dmesg`.
3. **El árbol de PixelExperience reserva memoria para `ramoops`** (`techpack`/`khaje.dtsi` línea 450): `ramoops@5D000000`, 4 MiB, `record-size 0x80000`, `console-size 0x100000`, `pmsg-size 0x200000`. El kernel de PX trae `PSTORE`; falta saber si el DTB de fábrica también lo reserva.

## Evidencias

(se curan con "verifica img")

## Pendientes

- [ ] Paso 1: `adb bugreport` con el kernel de fábrica.
- [ ] Paso 2: `dmesg` y `LAST KMSG` extraídos y sin datos personales (`logs/08-dmesg-fabrica.txt`).
- [ ] Paso 3: leer el `dmesg` de fábrica (banner, cmdline real, `pstore`, errores).
- [ ] Paso 4: `dmesg` con tu kernel y comparación.
- [ ] Paso 5: ¿`ramoops` en el DTB de fábrica?
- [ ] (Módulo 13) Provocar un *panic* controlado y leerlo desde `pstore`: requiere root (`echo c > /proc/sysrq-trigger`).
