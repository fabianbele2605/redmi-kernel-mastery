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
# Paso 1: entorno + código escrito a mano (modulos/hello_lab/hello_lab.c y Makefile) + compilar
export KSRC="$HOME/Escritorio/Mobil/src/kernel-px"
export KOUT="$HOME/Escritorio/Mobil/out-px"
source artifacts/build-env.sh                  # define $LAB y la función kmake (solo vive en esa terminal)
kmake M="$LAB/modulos/hello_lab" modules 2>&1 | tail -15
ls -l modulos/hello_lab/
```

## Hallazgos reales

1. **Antes de empezar se comprobó que el kernel lo admite todo** (ver «Datos de partida»), y que `proc_ops` no existe en 4.19: el nodo de `/proc` usa `struct file_operations`. Los módulos del fabricante no son un problema para el arranque: ya se vio en el módulo 6 que ningún ramdisk trae `.ko`.
2. **El código escrito a mano por el usuario salió idéntico al propuesto** (verificado con `cat -A`: tabuladores correctos, sin typos) y compiló a la primera. `modulos/hello_lab/hello_lab.c` mide 467 bytes y su `Makefile` (`obj-m += hello_lab.o`) 20 (sin salto de línea final: a Kbuild le da igual).
3. **`kmake` «no se encuentra» en una terminal nueva:** `kmake` no es un programa sino una **función de bash** definida por `source artifacts/build-env.sh`, y solo existe en esa terminal. Con una terminal nueva hay que volver a ejecutar los `export` y el `source`. Se diagnosticó antes de repetir probando el mismo comando en una carpeta temporal (mismo resultado: compila).
4. **Resultado de la compilación (Paso 1):** `CC [M] …/hello_lab.o`, `Building modules, stage 2.`, `MODPOST 1 modules`, `CC …/hello_lab.mod.o`, `LD [M] …/hello_lab.ko`. Se generaron `hello_lab.ko` (**30 168 bytes**), `hello_lab.o` (5 040), `hello_lab.mod.o` (26 720), `hello_lab.mod.c` (759), `modules.order` (68) y `Module.symvers` (**0 bytes**: el módulo no exporta ningún símbolo). Las salidas están ignoradas por `modulos/.gitignore`; solo el `.c` y el `Makefile` se versionan.
5. **Lo que lleva por dentro el `.ko` (comprobado por el mentor sobre una copia, 30 424 B por la ruta más larga):** `file` → `ELF 64-bit LSB relocatable, ARM aarch64 … with debug_info, not stripped`; `modinfo` → `license: GPL`, `author: fabian`, `description: Laboratorio: primer modulo`, **`vermagic: 4.19.297-uvite SMP preempt mod_unload modversions aarch64`** (exactamente el predicho), `name: hello_lab`, `depends:` vacío. Secciones: `.init.text` (0x20 = 32 B), `.exit.text` (0x1c = 28 B), `.modinfo` (0x9c), `.rodata.str1.1` (0x49, los textos), `.gnu.linkonce.this_module` (0x340 = 832 B, la `struct module`) y `__versions` (0x80, los CRC de los símbolos que importa). Símbolos: `T init_module` y `T cleanup_module` (los nombres reales que `module_init`/`module_exit` dan a tus dos funciones), `D __this_module` y **`U printk`**: la única función que no es suya y que el kernel resolverá al cargarlo.
6. **`init_module` en ARM64, 8 instrucciones (32 B):** `stp x29, x30, [sp, #-16]!` (guarda el registro de marco y el de retorno), `mov x29, sp`, `adrp x0, #0` y `add x0, x0, #0` (cargan la dirección del texto en `x0`, el primer argumento; los ceros se rellenan al cargar el módulo mediante las reubicaciones de `.rela.init.text`), `bl #0` (la llamada a `printk`, con su destino también por reubicar), `mov w0, wzr` (`return 0`), `ldp x29, x30, [sp], #16` y `ret`. Es la teoría del módulo 3 (argumentos en `x0`…, resultado en `w0`, `bl` y el registro de enlace `x30`) delante de código tuyo.

## Evidencias

**01 — Compilación de `hello_lab.ko` (hallazgo #4)**
Entorno cargado (`kernel:` `kernel-px`, `salida:` `out-px`), `kmake M="$LAB/modulos/hello_lab" modules` con `CC [M]`, `MODPOST` y `LD [M]`, y el `ls` con `hello_lab.ko` de 30 168 bytes.
![Compilación de hello_lab.ko](evidencias/01-compilacion-de-hello-lab-ko.png)

## Pendientes

- [x] Paso 1: `hello_lab.c` escrito a mano y compilado como `hello_lab.ko` (30 168 B).
- [ ] Paso 2: `.ko` inspeccionado (`file`, `modinfo`, `vermagic`).
- [ ] Paso 3: nodo `/proc/hello_lab` con `seq_file`.
- [ ] Paso 4: módulo integrado en el kernel y kernel recompilado.
- [ ] Paso 5: `printk` del módulo visto en el `dmesg` del teléfono.
- [ ] Paso 6: `cat /proc/hello_lab` desde `adb shell`.
- [ ] (Módulo 13) Cargarlo como `.ko` con `insmod` cuando haya root.
