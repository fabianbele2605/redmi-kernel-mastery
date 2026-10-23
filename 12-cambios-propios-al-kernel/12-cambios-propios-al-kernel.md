# Módulo 12 — Cambios propios al kernel

- Estado: En progreso
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

## Evidencias

Este módulo se documenta con los registros guardados, sin capturas de pantalla:
- `logs/12-build-hello2.log` — compilación incremental (28,6 s; `CC drivers/misc/hello_lab.o`).
- `logs/12-hash-boot-lab-hello2.txt` — SHA-256 de la imagen probada.
- `logs/08-dmesg-hello2.txt` — `dmesg` del arranque nuevo; línea 457: `hello_lab: … (cpus=8, HZ=250)`.
- `logs/12-build-kernel-init.log` y `logs/12-hash-boot-lab-kinit.txt` — el cambio 3 (ver hallazgo #11 sobre el registro).
- `logs/08-dmesg-kinit.txt` — líneas 1290-1292: `Freeing…` / `uvite: kernel_init…` / `Run /init`; control en 8439-8440.
- `patches/0003-lab-mensaje-al-terminar-kernel_init.patch` — el parche del cambio 3.

## Pendientes

- [x] Paso 1 de la guía: `CONFIG_LOCALVERSION` (módulo 7).
- [x] Paso 2 de la guía: un `pr_info` visible en `dmesg` (módulo 9) y ahora con datos comprobables (`cpus=8, HZ=250`).
- [x] Paso 3 de la guía: nodo `/proc` de solo lectura integrado (módulo 9).
- [x] Paso 4 de la guía: `pstore`/`ramoops` (módulo 8).
- [x] Primer commit de la serie y parche equivalente al `0001`.
- [x] Paso 5 de la guía: función no crítica **del propio árbol del kernel** modificada (`kernel_init`), con prueba en el `dmesg` y parche `0003` exportado.
- [ ] Paso 6 de la guía: un cambio de rendimiento, solo con las mediciones del módulo 10 antes y después.
- [ ] Probar la reversibilidad: `git revert` de un commit de la serie y comprobar que el kernel vuelve a comportarse como antes.
