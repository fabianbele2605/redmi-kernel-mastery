# Módulo 4 — Descargar el kernel `spes-r-oss`

- Estado: En progreso
- Fecha: 2026-10-06
- Fuente: <https://github.com/MiCode/Xiaomi_Kernel_OpenSource>, rama `spes-r-oss`
- Objetivo: tener el código fuente oficial de Xiaomi para `spes`, saber exactamente qué commit y qué versión de kernel es, y localizar su `defconfig` y las instrucciones de compilación. No se compila todavía (Módulo 5) y no hace falta el teléfono.

## Concepto

Un kernel no se compila "a ciegas": hay que saber qué árbol de código es, en qué commit está y qué configuración (`defconfig`) lo describe. Un commit identifica el contenido exacto; registrarlo hace el laboratorio **reproducible**. Se clona solo el último commit (`--depth=1`) de una sola rama para no descargar cientos de miles de commits de historial.

## Datos verificados antes de empezar (solo lectura, sin clonar)

- La rama `spes-r-oss` declara `VERSION = 4`, `PATCHLEVEL = 19`, **`SUBLEVEL = 157`**: la misma versión que corre el teléfono (`4.19.157-perf`).
- El `defconfig` está en `arch/arm64/configs/vendor/`: `spes_defconfig`, `spes-perf_defconfig`, `bengal_defconfig`, `bengal-perf_defconfig`. El kernel del teléfono lleva `-perf` en su versión, así que el candidato es `vendor/spes-perf_defconfig`. **[VERIFICAR]** contra la configuración real del teléfono.
- El commit `cb1ffc010755` (el sufijo `gcb1ffc010755` de `uname -r`) devuelve **404 en GitHub**: Xiaomi compiló el kernel del teléfono desde un commit interno no publicado. El código abierto es lo más cercano, no una copia exacta.
- Último commit de la rama `spes-r-oss` (visto con `git ls-remote`): `88afd32564211f4cfb60171ed8cbeaa734860601`.

## Práctica guiada

```bash
# Paso 1: clonar y registrar el commit
mkdir -p src
git clone --depth=1 --single-branch -b spes-r-oss https://github.com/MiCode/Xiaomi_Kernel_OpenSource.git src/kernel
git -C src/kernel rev-parse HEAD | tee logs/04-commit.txt
make -s -C src/kernel kernelversion      # 4.19.157  (con un aviso inofensivo sobre `python`)
du -sh src/kernel                        # 1,2G

# Paso 2: qué compilador y qué defconfig espera la rama
grep -n -E "CLANG_PREBUILT_BIN|^LLVM|CROSS_COMPILE" src/kernel/build.config.common src/kernel/build.config.aarch64
ls src/kernel/arch/arm64/configs/vendor/ | grep -E "^(spes|bengal)"
grep -c "=y" src/kernel/arch/arm64/configs/vendor/spes-perf_defconfig
grep -E "CONFIG_MODULES|CONFIG_LOCALVERSION|CONFIG_SECURITY_SELINUX=|CONFIG_PSTORE" src/kernel/arch/arm64/configs/vendor/spes-perf_defconfig
```

## Hallazgos reales

1. **El clonado es ligero:** 65 047 objetos, 186 MiB descargados y 1,2 GB en disco con `--depth=1`. El commit `88afd32564211f4cfb60171ed8cbeaa734860601` coincide con el que `git ls-remote` mostraba antes de clonar, y `kernelversion` da `4.19.157`, igual que el teléfono. El commit es de **2023-05-11** ("Kernel: Xiaomi kernel changes for Redmi Note 11 Android R"), seis meses anterior al kernel del teléfono (28 nov 2023).
2. **`make` avisa `python: No existe el archivo o el directorio`.** La línea 423 del `Makefile` define `CC = $(PYTHON) $(srctree)/scripts/gcc-wrapper.py $(REAL_CC)`: el compilador pasa por un script de Qualcomm que falla ante cualquier aviso nuevo. Ese script usa `#!/usr/bin/env python2` y `print "texto"` (**sintaxis de Python 2**), y Ubuntu 24.04 solo trae `python3`. Instalar `python-is-python3` no ayuda (daría un error de sintaxis). La solución es **no usar el wrapper**: pasar `CC=clang` en la línea de comandos, que prevalece sobre el Makefile. Para `kernelversion` el aviso es inofensivo.
3. **El método oficial se lee en `build.config.*` y `AndroidKernel.mk`** (no hay README): `LLVM=1`, `CROSS_COMPILE=aarch64-linux-gnu-`, `CROSS_COMPILE_COMPAT=arm-linux-gnueabi-` y `CLANG_TRIPLE=aarch64-linux-gnu-`, con `REAL_CC` apuntando a un Clang de AOSP. Coincide con la guía.
4. **El compilador esperado es `clang-r399163b`** (`CLANG_PREBUILT_BIN=prebuilts-master/clang/host/linux-x86/clang-r399163b/bin`), el Clang de AOSP de la era Android 11. El del host es Clang 18.1.3, muy posterior; es probable que el Módulo 5 obligue a descargar ese. **[VERIFICAR]**
5. **El `defconfig` correcto es `vendor/spes-perf_defconfig`** (656 opciones `=y`). Coincide con el kernel del teléfono porque define `CONFIG_LOCALVERSION="-perf"`, y el teléfono muestra `4.19.157-perf`.
6. **El sufijo `-gcb1ffc010755` sale de `CONFIG_LOCALVERSION_AUTO=y`**: el kernel añade `-g<hash del commit de Git>` a su versión. Por eso el teléfono muestra el hash de un commit interno de Xiaomi que no está en GitHub (404). Nuestro kernel mostrará el hash de **nuestro** commit (`-g88afd325…`, o `-dirty` si el árbol tiene cambios), lo que permitirá distinguir con `uname -r` cuál de los dos está corriendo.
7. **La configuración habilita lo que el curso necesita:** `CONFIG_MODULES=y` (módulos cargables, Módulo 9), `CONFIG_SECURITY_SELINUX=y` y `CONFIG_PSTORE=y` con `PSTORE_RAM`, `PSTORE_CONSOLE` y `PSTORE_PMSG` (registro de fallos, Módulo 8). Pendiente confirmar la firma de módulos (`CONFIG_MODULE_SIG*`) y que el Device Tree reserve memoria para `ramoops`. **[VERIFICAR]**

## Evidencias

(se curan con "verifica img")

## Pendientes

- [x] Clonar `spes-r-oss` en `src/kernel` y registrar el commit en `logs/04-commit.txt`.
- [x] Confirmar `kernelversion` = `4.19.157`.
- [x] Localizar `spes-perf_defconfig` en el árbol clonado.
- [x] Buscar qué compilador y qué variables pide la rama.
- [ ] Guardar la configuración real del teléfono (`/proc/config.gz`, si existe) en `logs/04-config-telefono.txt`.
- [ ] Diferido a Módulo 5: expandir `spes-perf_defconfig` a `.config` y compararlo con la del teléfono; descargar `clang-r399163b`.
