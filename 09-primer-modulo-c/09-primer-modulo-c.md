# Módulo 9 — Tu primer módulo del kernel, en C

- Estado: En progreso
- Fecha: 2026-10-22
- Kernel: `4.19.297-uvite` (`src/kernel-px`, salida en `out-px/`), compilado con Clang 11.0.1 de AOSP
- Imagen de prueba: `artifacts/px/boot-lab-ramoops.img` (con `ramoops_memreserve=4M`, módulo 8)
- Objetivo: escribir **a mano** un módulo en C, compilarlo contra tu kernel, entender qué lleva dentro (`vermagic`, símbolos) y hacerlo correr **dentro del teléfono**, leyendo su `printk` con las herramientas del módulo 8.

## Concepto

Un **módulo del kernel** es código que se añade al kernel en marcha, sin recompilarlo entero. Tiene dos puntos de entrada: `module_init(f)` (se ejecuta al cargarlo) y `module_exit(f)` (al descargarlo). Sus mensajes se escriben con `printk` (o `pr_info`, `pr_err`…) en el mismo búfer circular que lee `dmesg`.

Dos formas de llevar código al kernel:

| | Módulo (`.ko`) | Integrado (*built-in*) |
|---|---|---|
| Cuándo corre | Cuando alguien ejecuta `insmod` | Siempre, en el arranque del kernel |
| Cómo se compila | Aparte, con `obj-m` | Dentro de `vmlinux`, con `obj-y` |
| ¿Necesita root en el teléfono? | **Sí** (`insmod`) | **No**: lo arranca `fastboot boot` |

Esta ROM es de usuario: no se puede ser root, así que **no se puede ejecutar `insmod`** sin KernelSU (módulo 13). Por eso el plan es: (1) escribirlo y compilarlo como módulo para aprender lo que lleva (`modinfo`, `vermagic`), y (2) **integrarlo en el kernel** y arrancarlo, que no necesita root y deja ver su `printk` en el `dmesg`.

## Datos de partida (comprobados)

- `CONFIG_MODULES=y`, `MODULE_UNLOAD=y`, `MODVERSIONS=y`, `# CONFIG_MODULE_SIG is not set`, `CONFIG_PROC_FS=y`, `PRINTK=y`, `PRINTK_TIME=y`, `CONSOLE_LOGLEVEL_DEFAULT=7`, `MESSAGE_LOGLEVEL_DEFAULT=4`.
- **`proc_ops` no existe en este kernel** (llegó en la 5.6): un nodo en `/proc` se crea con `proc_create(nombre, modo, padre, const struct file_operations *)`.
- `vermagic` que llevará el `.ko`: `4.19.297-uvite SMP preempt mod_unload modversions aarch64` (`SMP`, `PREEMPT`, `MODULE_UNLOAD` y `MODVERSIONS` activos).
- El código fuente de los módulos vive en `modulos/` (versionado); sus salidas (`*.ko`, `*.o`…) están ignoradas por Git (`modulos/.gitignore`).
- `kmake M="$LAB/modulos/hello_lab" modules` compila un módulo externo con el mismo Clang, el mismo `.config` y las mismas opciones que el kernel.

## Plan

| Paso | Qué | Toca el teléfono |
|---|---|---|
| 1 | Escribir `hello_lab.c` (solo `printk`) a mano y compilarlo como `.ko` | No |
| 2 | Inspeccionar el `.ko`: `file`, `modinfo`, `vermagic`, símbolos, comparar con el kernel | No |
| 3 | Añadir un nodo `/proc/hello_lab` con `seq_file` y volver a compilar | No |
| 4 | Integrarlo en el árbol del kernel (`drivers/misc`, `Kconfig`, `Makefile`) y recompilar el kernel | No |
| 5 | Arrancar con `fastboot boot` y leer su `printk` en el `dmesg` | Arranque temporal |
| 6 | Leer `/proc/hello_lab` desde `adb shell` | Solo lectura |

## Práctica guiada

```bash
# se completa con los comandos reales ejecutados
```

## Hallazgos reales

1. **Antes de empezar se comprobó que el kernel lo admite todo** (ver «Datos de partida»), y que `proc_ops` no existe en 4.19: el nodo de `/proc` usa `struct file_operations`. Los módulos del fabricante no son un problema para el arranque: ya se vio en el módulo 6 que ningún ramdisk trae `.ko`.

## Evidencias

(se curan con "verifica img")

## Pendientes

- [ ] Paso 1: `hello_lab.c` escrito a mano y compilado como `hello_lab.ko`.
- [ ] Paso 2: `.ko` inspeccionado (`file`, `modinfo`, `vermagic`).
- [ ] Paso 3: nodo `/proc/hello_lab` con `seq_file`.
- [ ] Paso 4: módulo integrado en el kernel y kernel recompilado.
- [ ] Paso 5: `printk` del módulo visto en el `dmesg` del teléfono.
- [ ] Paso 6: `cat /proc/hello_lab` desde `adb shell`.
- [ ] (Módulo 13) Cargarlo como `.ko` con `insmod` cuando haya root.
