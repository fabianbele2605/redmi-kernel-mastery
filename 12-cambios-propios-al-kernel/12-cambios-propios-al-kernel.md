# Módulo 12 — Cambios propios al kernel

- Estado: Completado (el paso 6 se hizo después, con root del módulo 13; ver hallazgos #18 y #19-#23)
- Fecha: 2026-10-23
- Kernel: `4.19.297-uvite` (`src/kernel-px`, rama de trabajo `lab/cambio-01-hello-lab`, salida en `out-px/`), Clang 11.0.1 de AOSP
- Imagen de prueba: `artifacts/px/boot-lab-hello2.img` (`ramoops_memreserve=4M`), arrancada con `fastboot boot`
- Objetivo: modificar el kernel de `spes` de forma segura y verificable. Cada cambio es una iteración completa: **cambiar → compilar → arrancar → comprobar → anotar**, guardada como un commit propio y reversible con `git revert`.

## Concepto

Un cambio al kernel solo vale si se puede **comprobar contra algo que ya se sabía por otra vía**. Por eso cada cambio de este módulo imprime un dato cuyo valor se conoce de antemano (de `adb` o de la configuración) y se compara con lo que el kernel dice. Y cada cambio va en su propio commit: así se puede deshacer uno sin perder los demás.

## Práctica guiada

```bash
# Paso 1: guardar lo que ya había (hello_lab) como primer commit, en una rama de trabajo
cd ~/Escritorio/Mobil/src/kernel-px
git config --local user.name "fabian beleño"; git config --local user.email "fabianrobles321@outlook.com"
git checkout -b lab/cambio-01-hello-lab
git add drivers/misc/Kconfig drivers/misc/Makefile drivers/misc/hello_lab.c    # no `git add .`: scripts/__pycache__ queda fuera
git commit -m "lab: integrar hello_lab en drivers/misc"
git format-patch -1 -o /tmp/lab-patches

# Paso 2: datos que se conocen de antemano
grep -E "^CONFIG_HZ=|^CONFIG_NR_CPUS=" out-px/.config                  # CONFIG_HZ=250, CONFIG_NR_CPUS=8
adb shell 'ls /sys/devices/system/cpu | grep -c "^cpu[0-9]"; cat /sys/devices/system/cpu/online'   # 8, 0-7

# Paso 3: cambio 2 en modulos/hello_lab/hello_lab.c (#include <linux/cpumask.h> y un pr_info con num_online_cpus() y HZ)
source artifacts/entorno-px.sh
time kmake -j12 2>&1 | tee logs/12-build-hello2.log | tail -8         # real 28,6 s

# Paso 4: imagen y arranque temporal
cp out-px/arch/arm64/boot/Image.gz artifacts/px/Image-hello2.gz
python3 tools/mkbootimg/mkbootimg.py --header_version 3 --os_version 12.0.0 --os_patch_level 2023-12 --kernel artifacts/px/Image-hello2.gz --ramdisk backup/stock-unpacked/boot/ramdisk --cmdline 'ramoops_memreserve=4M' -o artifacts/px/boot-lab-hello2.img
sha256sum artifacts/px/boot-lab-hello2.img | tee logs/12-hash-boot-lab-hello2.txt
adb reboot bootloader && fastboot boot artifacts/px/boot-lab-hello2.img

# Paso 5: comprobar en el dmesg del teléfono
bash artifacts/capturar-dmesg.sh hello2          # logs/08-dmesg-hello2.txt (1 a 4 min; no interrumpir)
grep -n "hello_lab" logs/08-dmesg-hello2.txt
# Cambio 3 (en el propio kernel): una línea en init/main.c, rama aparte
cd ~/Escritorio/Mobil/src/kernel-px && git checkout -b lab/cambio-02-kernel-init
# en kernel_init(), justo después de rcu_end_inkernel_boot();:
#     pr_info("uvite: kernel_init termina el arranque del kernel\n");
source artifacts/entorno-px.sh && time kmake -j12 2>&1 | tee logs/12-build-kernel-init.log | tail -8        # real 22,2 s
cp out-px/arch/arm64/boot/Image.gz artifacts/px/Image-kinit.gz
python3 tools/mkbootimg/mkbootimg.py --header_version 3 --os_version 12.0.0 --os_patch_level 2023-12 --kernel artifacts/px/Image-kinit.gz --ramdisk backup/stock-unpacked/boot/ramdisk --cmdline 'ramoops_memreserve=4M' -o artifacts/px/boot-lab-kinit.img
sha256sum artifacts/px/boot-lab-kinit.img | tee logs/12-hash-boot-lab-kinit.txt
adb reboot bootloader && fastboot boot artifacts/px/boot-lab-kinit.img
bash artifacts/capturar-dmesg.sh kinit
grep -n -E "Freeing unused kernel memory|uvite: kernel_init|Run /init" logs/08-dmesg-kinit.txt
cd src/kernel-px && git add init/main.c && git commit -m "lab: mensaje al terminar kernel_init"
git format-patch -1 -o ~/Escritorio/Mobil/patches --start-number 3     # patches/0003-lab-mensaje-al-terminar-kernel_init.patch
# Reversibilidad: deshacer el cambio 3 con git revert, en una rama desechable
cd ~/Escritorio/Mobil/src/kernel-px
git checkout -b lab/prueba-revert
git revert --no-edit HEAD                                   # d6656e06d Revert "lab: mensaje al terminar kernel_init"
git diff lab/cambio-01-hello-lab --stat -- init/main.c      # vacio: main.c vuelve a ser el de antes del cambio 3
cd ~/Escritorio/Mobil && source artifacts/entorno-px.sh && time kmake -j12 2>&1 | tee logs/12-build-revert.log | tail -6     # real 21,6 s
cp out-px/arch/arm64/boot/Image.gz artifacts/px/Image-revert.gz
python3 tools/mkbootimg/mkbootimg.py --header_version 3 --os_version 12.0.0 --os_patch_level 2023-12 --kernel artifacts/px/Image-revert.gz --ramdisk backup/stock-unpacked/boot/ramdisk --cmdline 'ramoops_memreserve=4M' -o artifacts/px/boot-lab-revert.img
sha256sum artifacts/px/boot-lab-revert.img | tee logs/12-hash-boot-lab-revert.txt
fastboot boot artifacts/px/boot-lab-revert.img && bash artifacts/capturar-dmesg.sh revert
grep -n -E "Freeing unused kernel memory|uvite: kernel_init|Run /init|hello_lab" logs/08-dmesg-revert.txt
git -C src/kernel-px checkout lab/cambio-02-kernel-init     # volver a la rama buena
# Paso 6 (diferido en su dia, hecho en el modulo 13 con root): read_ahead_kb de /data, medido
adb shell 'su -c "mount | grep \" /data \""'                                   # /dev/block/dm-40 type f2fs ... inlinecrypt
adb shell 'su -c "cat /sys/block/sda/queue/read_ahead_kb /sys/block/dm-40/queue/read_ahead_kb"'   # 128 y 512 KB: /data usa dm-40, no sda
bash artifacts/medir-readahead.sh r1   3 512  2048 1024     # tanda 1: A=512 primero, B=2048 despues
bash artifacts/medir-readahead.sh ctrl 3 512  512  1024     # control A/A: el mismo valor dos veces
bash artifacts/medir-readahead.sh inv  3 2048 512  1024     # orden invertido: B primero
```

## Hallazgos reales

1. **Estado de la lista de la guía.** Los pasos 1 (`CONFIG_LOCALVERSION`, módulo 7), 2 (un `pr_info` visible en `dmesg`, módulo 9), 3 (nodo `/proc`, módulo 9) y 4 (`pstore`/`ramoops`, módulo 8) ya estaban hechos. Lo que faltaba era hacerlo **en la forma de la guía**: un commit por cambio, en una rama, con su parche.
2. **Identidad de Git distinta en el repositorio del kernel.** El repositorio del curso comitea como `fabian beleño <fabianrobles321@outlook.com>`, pero el del kernel usaba `fabianrobles26` (de la configuración global). Un `git format-patch` escribe esa identidad en la cabecera `From:` del parche, y los parches se publican. Se fijó la identidad **solo en el repositorio del kernel** (`--local`) antes de crear ningún commit.
3. **Primer commit: `9a843856f lab: integrar hello_lab en drivers/misc`** en la rama `lab/cambio-01-hello-lab`, que cuelga de `dad6f6ab2` (la rama `fourteen`). Son 3 archivos y 10 líneas; el enlace simbólico figura con modo `120000`. `scripts/__pycache__/`, creado por accidente en el módulo 9, quedó **fuera** porque se añadieron los archivos uno a uno. El parche exportado es **idéntico a `patches/0001`** salvo las dos líneas finales de firma que añade `format-patch` (`-- ` y `2.53.0`).
4. **Cambio 2: `hello_lab` informa de `cpus` y `HZ`.** Se añadió `#include <linux/cpumask.h>` y el `pr_info` pasó a `"hello_lab: cargado, nodo /proc/hello_lab creado (cpus=%u, HZ=%d)\n", num_online_cpus(), HZ`. Los valores esperados se fijaron **antes** de compilar, por otras dos vías: **8** CPUs (`adb`: `cpu0`–`cpu7`, `online = 0-7`) y **`HZ` = 250** (`out-px/.config`: `CONFIG_HZ=250`).
5. **Compilación incremental: 28,6 s reales**, 0 errores y 0 avisos; se recompiló solo `drivers/misc/hello_lab.o` (línea 12 del registro) y el texto nuevo aparece dentro de `vmlinux`. Imagen `boot-lab-hello2.img`, SHA-256 `06b17a10fae0274da8a3f4952c9ab69e9bbba6f0b9905ece065da4fbc1d1309a`. `fastboot boot`: `Sending 'boot.img' (36532 KB) OKAY [0.871s]`, `Booting OKAY [0.318s]`.
6. **Comprobado en el teléfono: `[    1.196260] hello_lab: cargado, nodo /proc/hello_lab creado (cpus=8, HZ=250)`** (`logs/08-dmesg-hello2.txt`, línea 457). Los dos números coinciden con lo esperado. El teléfono arrancó con `4.19.297-uvite` y un uptime de 57 s (arranque nuevo).
7. **La prueba de fugas con la comprobación del Wi-Fi pasó** (`serial:0 PARTUUID:0 UUID:0 15-dígitos:0 MAC:0 SSID:0`): es la primera captura hecha con el script corregido tras el hallazgo #28 del módulo 9. En el archivo, la línea `Connecting to` sale como `[SSID-TAPADO]`, y no hay «FLIA» ni «BELENO».
8. **Limitación del diseño por enlace simbólico.** `drivers/misc/hello_lab.c` es un enlace a `modulos/hello_lab/hello_lab.c`. **El cambio 2 vive en el archivo del repositorio del curso, no en el del kernel**, así que `git format-patch` sobre `src/kernel-px` saldría vacío para él. Se versiona con un commit en el repositorio del curso (reversible igual con `git revert`). Para los cambios que sí toquen archivos del propio árbol del kernel, el flujo de parche de la guía se aplica tal cual.

9. **Cambio 3, en el propio kernel: una línea en `init/main.c`.** En `kernel_init()` (`init/main.c:1096`), después de `rcu_end_inkernel_boot();` (línea 1117): `pr_info("uvite: kernel_init termina el arranque del kernel\n");`. Está sobre la rama `lab/cambio-02-kernel-init`, que cuelga de `lab/cambio-01-hello-lab`. El punto se eligió **leyendo el código**: el mensaje `Run %s as init process` lo imprime `run_init_process()` (línea 1040), que se llama **después** de `rcu_end_inkernel_boot()`; por tanto la línea nueva debía caer entre `Freeing unused kernel memory` y `Run /init`. Esa predicción se fijó **antes** de compilar.
10. **Errores del mentor en este paso.** (a) Dijo que este cambio compilaría más despacio por tocar una pieza central: **tardó 22,2 s**, menos que el cambio 2 (28,6 s); lo caro es el reenlazado, no el archivo. (b) Al preparar la predicción, un `grep ... | head -6` cortó la salida y se afirmó que `Freeing unused kernel memory` **no estaba** en el `dmesg`; sí estaba (línea 1286). Moraleja: un `head` oculta resultados; antes de afirmar que algo no existe hay que buscarlo sin recortar.
11. **El registro de compilación no contiene la compilación de `main.c`.** `logs/12-build-kernel-init.log` solo muestra `CC init/version.o` y el reenlazado; `out-px/init/main.o` es de las 12:52:57 y el registro empieza a las 12:53:04: **alguien compiló una vez antes** (probablemente la orden se ejecutó dos veces). El resultado es válido (`main.o` contiene el texto nuevo, es posterior a `main.c` y `vmlinux` es posterior a `main.o`), pero el registro no es la compilación completa.
12. **Imagen y arranque.** `boot-lab-kinit.img` (37 412 864 B), SHA-256 `7576108121576043f3c77449f3feda6c60d650dd0c0b7385c67def29061d9683`. `fastboot boot`: `Sending 'boot.img' (36536 KB) OKAY [0.867s]`, `Booting OKAY [0.318s]`. Android arrancó con `4.19.297-uvite` y un uptime de 84 s (arranque nuevo).
13. **Comprobado en el `dmesg` del teléfono, con control incluido** (`logs/08-dmesg-kinit.txt`): `[2.073305] Freeing unused kernel memory: 1280K`, **`[2.073397] uvite: kernel_init termina el arranque del kernel`**, `[2.073401] Run /init as init process` (líneas 1290-1292): entre las dos, como se predijo, y a 4 µs de `Run /init`. El mismo archivo trae `LAST KMSG` (el arranque anterior, sin el cambio): ahí `Freeing…` y `Run /init` aparecen **seguidas** (líneas 8439-8440), sin la línea nueva. La prueba de fugas pasó (`SSID:0`).
14. **Commit y parche del cambio 3.** `52174c250 lab: mensaje al terminar kernel_init`, exportado con `git format-patch -1 --start-number 3` a **`patches/0003-lab-mensaje-al-terminar-kernel_init.patch`** (1 archivo, 1 línea). Su cabecera `From:` lleva la identidad fijada en el hallazgo #2. Verificado: **aplica limpio sobre el `init/main.c` de `fourteen`** y se rechaza al aplicarlo dos veces.

15. **`git revert` deshace un cambio sin borrar historia.** En la rama desechable `lab/prueba-revert`, `git revert --no-edit HEAD` creó `d6656e06d Revert "lab: mensaje al terminar kernel_init"` (`1 file changed, 1 deletion(-)`) **encima** de `52174c250`, que sigue en el historial. `git diff lab/cambio-01-hello-lab -- init/main.c` salió vacío y `git diff fourteen -- init/main.c` también: `init/main.c` quedó idéntico al original. La rama se conservó como constancia del ejercicio.
16. **Recompilación y arranque con el cambio deshecho.** 21,6 s reales, 0 errores y 0 avisos; esta vez el registro **sí** contiene `CC init/main.o` (línea 5) y la cadena `uvite: kernel_init` **ya no está en `vmlinux`** (0 apariciones). `boot-lab-revert.img`, SHA-256 `f55a9ff7b3bf69c6b0b1b96ec3e8982bbbdeeeed0d686316bd5d1f313eb36253`; `fastboot boot` `OKAY [0.869s]` / `OKAY [0.317s]`; uptime de 40 s (arranque nuevo).
17. **Comprobado en el `dmesg` (`logs/08-dmesg-revert.txt`), con el arranque anterior como control en el mismo archivo.** Arranque actual (cambio 3 revertido), líneas 1277-1278: `[1.873630] Freeing unused kernel memory` y `[1.873721] Run /init as init process`, **seguidas, sin la línea de `uvite`**. `LAST KMSG` (el arranque anterior, con el cambio 3), líneas 8125-8127: `Freeing…` / **`[2.073397] uvite: kernel_init termina el arranque del kernel`** / `Run /init`. Y **`hello_lab … (cpus=8, HZ=250)` sigue presente** (línea 458): el revert de un commit no afectó a los otros dos cambios de la serie. Prueba de fugas: `SSID:0`; sin «FLIA» ni «BELENO».

18. **El paso 6 (cambio de rendimiento) no se puede medir sin root, y por eso se difiere.** Antes de elegir el cambio se comprobó qué puede leer y hacer el usuario `shell`: `/sys/block/*/queue/read_ahead_kb` no es legible, `/sys/block/sda/queue/scheduler` da `Permission denied`, `sched_latency_ns`, `sched_min_granularity_ns` y `sched_wakeup_granularity_ns` no son legibles, `/proc/sys/vm/drop_caches` **no se puede escribir** y el `dd` de Android rechaza `iflag=direct` (`dd: bad iflag=direct`). Sin vaciar la caché de páginas ni poder leer el parámetro que se cambiaría, una medida de «antes y después» mediría la caché y no el cambio; y el módulo 10 mostró que la misma medida varía entre repeticiones iguales (frecuencia media de los grandes: 2 304, 2 392 y 2 400 MHz). El kernel usa `CONFIG_DEFAULT_IOSCHED="cfq"` y `CONFIG_HZ=250`. **Decisión:** no inventar un cambio sin forma de medirlo; el paso 6 queda pendiente hasta tener root (módulo 13).

19. **Antes de medir, el dispositivo correcto.** El plan era cambiar `read_ahead_kb` de `sda` (128 KB), pero `/data` es **`f2fs` sobre `/dev/block/dm-40`** (con `inlinecrypt`), y `dm-40` tiene **512 KB**. Cambiar `sda` no habría tocado nada de lo que lee el archivo de prueba. Se descubrió **leyendo el montaje antes de tocar nada**.
20. **Diseño del experimento: una sola variable y reversible.** `artifacts/medir-readahead.sh` cambia solo `/sys/block/dm-40/queue/read_ahead_kb` (512 KB frente a 2048 KB), lee en secuencia un archivo de 1 GB con `dd bs=64k`, **vacía la caché antes de cada lectura** (`drop_caches`), alterna los valores y restaura el original aunque se interrumpa (`trap`). `artifacts/ra-una-lectura.sh` es la parte que corre en el teléfono; el `date +%s%N` de Android funciona (mide 1 031 ms tras `sleep 1`). `quiet` varió de 29,15 a 29,77 °C: sin efecto térmico.
21. **La primera tanda engañaba.** `r1` (512 primero, 2048 después): 512 KB = 1 524 ms de media (672 MB/s) y 2048 KB = 1 157 ms (886 MB/s), **+31,7 %**, y los rangos no se solapaban. Pero el diseño tenía un fallo del mentor: dentro de cada pareja siempre iba primero el valor de partida. Se añadieron dos controles.
22. **El control A/A mostró que el ruido es del tamaño del efecto.** `ctrl` (512 contra 512): parejas (1 077, 1 411), (1 420, 1 415), (1 121, 1 416) ms; **dos lecturas idénticas difieren hasta un 32 %**. Con todos los datos juntos los rangos **sí se solapan** (dos lecturas a 512 KB, 1 077 y 1 121 ms, fueron más rápidas que la peor de 2048 KB, 1 189 ms): la «separación» de `r1` fue suerte de una muestra pequeña. La segunda lectura de cada pareja salió igual o más lenta, al revés de lo que favorecería a 2048 KB, así que el orden no explica la mejora.
23. **Resultado, con sus límites.** Con las 18 lecturas (`r1`, `ctrl`, `inv`): 512 KB, n = 12, media **1 365 ms**, mediana 1 413, rango 1 077–1 571; 2048 KB, n = 6, media **1 116 ms**, mediana 1 103, rango 1 025–1 189. **−18,2 % de tiempo** (−21,9 % por medianas), prueba de permutación **p = 0,0015**; por tandas: **−24,1 %** (`r1`) y **−18,4 %** (`inv`, orden invertido). Es decir: **más lectura anticipada acelera la lectura secuencial en torno a un 18-24 %**. No se puede generalizar: es una lectura secuencial sintética (archivo de ceros, bloques de 64 KB), el mejor caso para la lectura anticipada; no dice nada de lecturas aleatorias (abrir apps) ni del coste en memoria; y los resultados a 512 KB son **bimodales** (~1 100 y ~1 415 ms con el mismo ajuste), señal de un factor no controlado. El cambio es en **tiempo de ejecución** (no recompila el kernel) y **se pierde al reiniciar**: el valor original (512 KB) se restauró al terminar cada tanda.

## Evidencias

Este módulo se documenta con los registros guardados, sin capturas de pantalla:
- `logs/12-build-hello2.log` — compilación incremental (28,6 s; `CC drivers/misc/hello_lab.o`).
- `logs/12-hash-boot-lab-hello2.txt` — SHA-256 de la imagen probada.
- `logs/08-dmesg-hello2.txt` — `dmesg` del arranque nuevo; línea 457: `hello_lab: … (cpus=8, HZ=250)`.
- `logs/12-build-kernel-init.log` y `logs/12-hash-boot-lab-kinit.txt` — el cambio 3 (ver hallazgo #11 sobre el registro).
- `logs/08-dmesg-kinit.txt` — líneas 1290-1292: `Freeing…` / `uvite: kernel_init…` / `Run /init`; control en 8439-8440.
- `patches/0003-lab-mensaje-al-terminar-kernel_init.patch` — el parche del cambio 3.
- `logs/12-readahead-r1.csv`, `logs/12-readahead-ctrl.csv`, `logs/12-readahead-inv.csv` — las 18 lecturas del paso 6 (hallazgos #21 a #23); scripts `artifacts/medir-readahead.sh` y `artifacts/ra-una-lectura.sh`.
- `logs/12-build-revert.log`, `logs/12-hash-boot-lab-revert.txt` y `logs/08-dmesg-revert.txt` — la prueba de reversibilidad (líneas 1277-1278 del `dmesg` y 8125-8127 del arranque anterior).

## Pendientes

- [x] Paso 1 de la guía: `CONFIG_LOCALVERSION` (módulo 7).
- [x] Paso 2 de la guía: un `pr_info` visible en `dmesg` (módulo 9) y ahora con datos comprobables (`cpus=8, HZ=250`).
- [x] Paso 3 de la guía: nodo `/proc` de solo lectura integrado (módulo 9).
- [x] Paso 4 de la guía: `pstore`/`ramoops` (módulo 8).
- [x] Primer commit de la serie y parche equivalente al `0001`.
- [x] Paso 5 de la guía: función no crítica **del propio árbol del kernel** modificada (`kernel_init`), con prueba en el `dmesg` y parche `0003` exportado.
- [x] Paso 6 de la guía: cambio de rendimiento con mediciones antes y después (hecho en el módulo 13 con root): `read_ahead_kb` de `dm-40`, 512 → 2048 KB, −18 % a −24 % de tiempo en lectura secuencial, con control A/A y orden invertido. No se generaliza (hallazgo #23).
- [x] Reversibilidad: `git revert` del cambio 3, recompilado y arrancado; su línea desaparece del `dmesg` y los otros cambios siguen.
