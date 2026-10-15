# Módulo 6 — Analizar el `boot.img` original

- Estado: En progreso
- Fecha: 2026-10-14
- Imágenes: `backup/stock/` (copiadas de la ROM `V14.0.5.0.TGCMIXM`, verificadas con `sha256sum -c logs/03-hash-stock.txt`: las cinco coinciden)
- Herramienta: `tools/mkbootimg/unpack_bootimg.py` (AOSP `platform-tools-34.0.4`, módulo 1)
- Objetivo: entender qué hay dentro de la imagen de arranque de fábrica (kernel, ramdisk, Device Tree, línea de comandos), para decidir **qué piezas reutilizamos** y qué piezas sustituye nuestro kernel en el Módulo 7. Todo se hace sobre archivos en el disco: no hace falta el teléfono.

## Concepto

El arranque de Android (`boot.img`) es un contenedor con un **cabecera** y varias piezas: el **kernel**, un **ramdisk** (sistema de archivos mínimo que arranca `init`), y en versiones modernas de la cabecera (3 y 4) parte de esas piezas se mueven a **`vendor_boot`**: el ramdisk del fabricante, el **Device Tree (DTB)** y parte de la línea de comandos. Por eso es clave saber la **versión de cabecera**: decide dónde vive cada pieza y qué tenemos que reempaquetar.

En un teléfono A/B hay dos copias de cada partición (`boot_a`/`boot_b`, `vendor_boot_a`/`vendor_boot_b`). Las imágenes de la ROM son un volcado de **una** partición, rellenado con ceros hasta su tamaño: `boot.img` y `vendor_boot.img` miden 100 663 296 bytes (96 MiB) cada una, `dtbo.img` 8 388 608 (8 MiB), `vbmeta.img` 8 192 y `vbmeta_system.img` 4 096.

## Datos de partida

- Kernel de fábrica: `4.19.157-perf-gcb1ffc010755` (compilado el 28 nov 2023). Nuestro kernel: `4.19.297-uvite` (`artifacts/px/`, hashes en `logs/05-hash-px.txt`).
- El árbol de PixelExperience trae sus propios Device Tree (`dtb.img`, `dtbo.img`), pero **no sabemos si son compatibles** con el hardware real de este teléfono ni con el DTB que arranca MIUI. Por eso conviene reutilizar el DTB de fábrica de `vendor_boot`.
- Falta en el kernel compilado: 8 funciones propias de MIUI (módulo 5, hallazgo #23).

## Plan

| Paso | Qué | Resultado buscado |
|---|---|---|
| 1 | Desempaquetar `boot.img` | Versión de cabecera, tamaños, `cmdline` |
| 2 | Identificar el kernel de fábrica dentro del `boot.img` | Formato (¿gzip, sin comprimir?) y versión |
| 3 | Desempaquetar `vendor_boot.img` | ¿Dónde está el DTB? `cmdline` del fabricante |
| 4 | Mirar el ramdisk (`cpio`) | Módulos del fabricante (`.ko`) y `init` |
| 5 | Comparar con lo que compilamos | Qué sustituye nuestro kernel y qué se reutiliza |
| 6 | `dtbo.img` y `vbmeta` | Estado de la verificación de arranque (AVB) |

## Práctica guiada

```bash
# se completa con los comandos reales ejecutados
```

## Hallazgos reales

(se documentan aquí a medida que aparezcan)

## Evidencias

(se curan con "verifica img")

## Pendientes

- [ ] Paso 1: `boot.img` desempaquetado y versión de cabecera anotada.
- [ ] Paso 2: formato y versión del kernel de fábrica.
- [ ] Paso 3: `vendor_boot.img` desempaquetado; ¿el DTB viaja ahí?
- [ ] Paso 4: contenido del ramdisk y de los módulos del fabricante.
- [ ] Paso 5: comparación con nuestra compilación.
- [ ] Paso 6: estado de AVB en `vbmeta`.
