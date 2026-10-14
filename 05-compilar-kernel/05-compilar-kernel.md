# Módulo 5 — Compilar el kernel sin modificarlo

- Estado: En progreso
- Fecha: 2026-10-13
- Árbol: `src/kernel`, rama `spes-r-oss`, commit `88afd32564211f4cfb60171ed8cbeaa734860601`, kernel 4.19.157
- Objetivo: producir con tus propias manos la imagen `Image` (y su DTB) de un kernel **sin cambios**, entendiendo cada error que aparezca. Es la línea base contra la que se medirá todo lo demás.

## Concepto

Compilar el kernel de un teléfono desde un PC x86_64 es **compilación cruzada**: el compilador corre en x86_64 y genera código ARM64. Hacen falta cuatro cosas bien alineadas: un **compilador** de la época del kernel, el **`defconfig`** correcto, las **variables** que le dicen a `make` qué herramientas usar, y un directorio de salida (`O=out/`) separado del código para no ensuciar Git.

Se divide en dos sesiones:

- **Sesión A (con las manos en el teclado, ~40 min):** conseguir el Clang, comprobar que funciona, expandir el `defconfig` a `.config` y compararlo con el del teléfono.
- **Sesión B (~1 h de espera):** la compilación completa. Laptop enchufada y sin suspenderse.

## Datos de partida (módulos 1 y 4)

- Host: Ubuntu 24.04, Ryzen 5 7530U (12 hilos), 14 GiB de RAM, **59 GB libres** (87 % usado). Se compilará con `-j8`.
- Clang del sistema: 18.1.3, demasiado nuevo para un kernel 4.19. El kernel de fábrica se compiló con **Clang 10.0.7** (`CONFIG_CLANG_VERSION=100007`, sin LTO).
- `build.config.common` pide `clang-r399163b`, que **no existe** en la rama `android11-release` de AOSP (404). Sí existe **`clang-r383902`**, declarado como "11.0.1 based on r383902" en su `AndroidVersion.txt`. El servidor de AOSP descarga a ≈ 4 MB/s.
- El `Makefile` define `CC = $(PYTHON) scripts/gcc-wrapper.py $(REAL_CC)` y ese script es de Python 2. Se evita pasando `CC=clang` en la línea de comandos.
- El `defconfig` impone `CONFIG_MODULE_SIG_FORCE=y`; los módulos propios se firmarán con la clave que genere la compilación.

## Plan

| Paso | Qué | Sesión |
|---|---|---|
| 1 | Descargar `clang-r383902` de AOSP a `tools/` | A |
| 2 | Prueba de humo: compilar un `hello.c` para ARM64 con ese Clang | A |
| 3 | Expandir `vendor/spes-perf_defconfig` a `.config` en `out/` | A |
| 4 | Comparar ese `.config` con el del teléfono (`scripts/diffconfig`) | A |
| 5 | Compilar con `CC=clang`, `-j8`, y guardar el log | B |
| 6 | Localizar `Image`/`Image.gz-dtb` y guardar sus hashes | B |

## Práctica guiada

```bash
# se completa con los comandos reales ejecutados
```

## Hallazgos reales

(se documentan aquí a medida que aparezcan)

## Evidencias

(se curan con "verifica img")

## Pendientes

- [ ] Paso 1: `clang-r383902` descargado y funcionando.
- [ ] Paso 2: prueba de humo ARM64.
- [ ] Paso 3: `out/.config` generado desde `spes-perf_defconfig`.
- [ ] Paso 4: diferencias frente al `config.gz` del teléfono anotadas.
- [ ] Paso 5: compilación terminada y log en `logs/05-build-01.log`.
- [ ] Paso 6: `Image` localizada y con hash.
