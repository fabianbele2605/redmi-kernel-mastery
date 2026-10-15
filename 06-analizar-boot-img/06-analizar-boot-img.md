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
# Paso 1: cabecera del boot.img (--out siempre explícito: por defecto sería ./out, que ya existe)
mkdir -p backup/stock-unpacked
python3 tools/mkbootimg/unpack_bootimg.py --boot_img backup/stock/boot.img --out backup/stock-unpacked/boot | tee logs/06-boot-cabecera.txt
ls -l backup/stock-unpacked/boot
file backup/stock-unpacked/boot/kernel

# Paso 2: receta para reconstruirlo y versión del kernel de fábrica
python3 tools/mkbootimg/unpack_bootimg.py --boot_img backup/stock/boot.img --out backup/stock-unpacked/boot --format mkbootimg
zcat backup/stock-unpacked/boot/kernel > backup/stock-unpacked/boot/kernel.raw
strings backup/stock-unpacked/boot/kernel.raw | grep -m1 "Linux version"
file backup/stock-unpacked/boot/kernel.raw

# Paso 3: vendor_boot
python3 tools/mkbootimg/unpack_bootimg.py --boot_img backup/stock/vendor_boot.img --out backup/stock-unpacked/vendor_boot | tee logs/06-vendor-boot-cabecera.txt
ls -l backup/stock-unpacked/vendor_boot
file backup/stock-unpacked/vendor_boot/*

# Paso 4: contenido de los ramdisks (solo se LISTA con cpio -t, no se extrae nada)
zcat backup/stock-unpacked/vendor_boot/vendor_ramdisk | cpio -tv
zcat backup/stock-unpacked/boot/ramdisk | cpio -t | wc -l          # 885 entradas
zcat backup/stock-unpacked/boot/ramdisk | cpio -t | head -30
zcat backup/stock-unpacked/boot/ramdisk | cpio -t | grep -c "\.ko$"   # 0
```

## Hallazgos reales

1. **`boot.img` es versión de cabecera 3.** `unpack_bootimg` da `boot magic: ANDROID!`, `boot image header version: 3`, `kernel_size: 18862488`, `ramdisk size: 19769994`, `os version: 12.0.0`, `os patch level: 2023-12` y **`command line args:` vacío**. (`os version 12.0.0` es la etiqueta de la imagen de arranque; el sistema es Android 13.) Con la cabecera 3, el `boot.img` solo lleva el kernel y un ramdisk genérico; lo específico del fabricante va en `vendor_boot`.
2. **El kernel de fábrica es un `Image.gz`:** `file` dice `gzip compressed data … original size modulo 2^32 41105920`, y descomprimido (`zcat`) es `Linux kernel ARM64 boot executable Image, little-endian, 4K pages` de **41 105 920 bytes**, con la marca `ARMd` en el byte 56 igual que el nuestro. El nuestro mide 36 719 104 B sin comprimir (17 619 346 B en gzip contra 18 862 488 B). El formato es compatible, así que nuestro `Image.gz` puede ocupar su lugar.
3. **La receta exacta del `boot.img` de fábrica** (`--format mkbootimg`): `--header_version 3 --os_version 12.0.0 --os_patch_level 2023-12 --kernel … --ramdisk … --cmdline ''`. Es la que se usará en el Módulo 7: solo cambia el kernel.
4. **El kernel de fábrica confirma lo medido en el Módulo 2:** `Linux version 4.19.157-perf-gcb1ffc010755 (builder@pangu-build-component-vendor-448263-0h5j6-27sw5-mphfb) (clang version 10.0.7 for Android NDK, GNU ld (binutils-2.27-bd24d23f) 2.27.0.20170315) #1 SMP PREEMPT Tue Nov 28 05:56:27 UTC 2023`, idéntico al `uname -a` del teléfono. **Corrección al hallazgo #10 del Módulo 5:** se compiló con el **Clang 10.0.7 del NDK de Android** (no con el Snapdragon LLVM de Qualcomm) y se enlazó con **GNU ld**, **no LLD**. Nosotros usamos LLD 11.0.1; el `builder@pangu-…` es el servidor de compilación de Xiaomi (por eso el commit `cb1ffc010755` no está en GitHub).
5. **`vendor_boot.img` también es cabecera 3** (`boot magic: VNDRBOOT`, `vendor boot image header version: 3`, `page size: 0x1000`, `kernel load address: 0x00008000`, `ramdisk load address: 0x01000000`, `kernel tags load address: 0x100`, `vendor boot image header size: 2112`).
6. **El Device Tree de fábrica está en `vendor_boot`:** `dtb size: 5598424` (`dtb address: 0x1f00000`). Es un archivo con **varios DTB concatenados**: `file` solo describe el primero (`Device Tree Blob version 17, size=357914`). Responde la pregunta abierta desde el Módulo 4: sí podemos conservar el DTB original, porque el Módulo 7 solo sustituye el kernel de `boot`.
7. **La línea de comandos está en `vendor_boot`** (la de `boot` está vacía): `console=ttyMSM0,115200n8 earlycon=msm_geni_serial,0x4a90000 androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 swiotlb=2048 loop.max_part=7 buildvariant=user`. **No contiene número de serie** (lo añade el bootloader en tiempo de arranque). Destacan `earlycon=msm_geni_serial,0x4a90000` (consola temprana por la UART del SoC) y `buildvariant=user`.
8. **El ramdisk de `vendor_boot` es diminuto:** `vendor ramdisk size: 2290` bytes (gzip; descomprimido, 9 728). Casi vacío: **no trae los módulos del kernel `.ko` del fabricante** en esta etapa. Esto atenúa la preocupación del Módulo 5 (#18) sobre que nuestro kernel no pudiera cargar módulos firmados por Xiaomi durante el arranque temprano. **[VERIFICAR]** en qué partición están los módulos (`vendor`/`vendor_dlkm` dentro de `super`, o integrados).
9. **Dos trampas evitadas:** `unpack_bootimg` extrae por defecto a una carpeta `./out`, que en este proyecto ya existe (compilación del árbol oficial); por eso se indicó siempre `--out backup/stock-unpacked/…`. Y todo lo desempaquetado queda en `backup/` (ignorada por Git), porque contiene el kernel binario de Xiaomi.
10. **El ramdisk de `vendor_boot` solo trae el `fstab`:** `cpio -tv` lista únicamente `first_stage_ramdisk/` y `first_stage_ramdisk/fstab.default` (9 168 bytes). El `fstab` monta en el arranque temprano `system`, `system_ext`, `vendor`, `product` y `mi_ext` (todos `ext4`, `ro`), y varias superposiciones `overlay` de `/product/*` apoyadas en `/mnt/vendor/mi_ext/…` (la personalización de MIUI). Son particiones lógicas dentro de `super`.
11. **El ramdisk de `boot` tiene 885 entradas (≈ 38,4 MB) y es de tipo «recovery en boot»:** además de `init`, `system/bin` (218 entradas), `system/lib64` (74) y `system/etc` (42), trae `init.recovery.hardware.rc`, `init.recovery.qcom.rc`, `miui.factoryreset.rc`/`.fstab`, `first_stage_ramdisk/avb/{q,r,s}-gsi.avbpubkey` (claves de las imágenes genéricas de Google), `verity_key`, `vendor_file_contexts` y `default.prop`. El teléfono no tiene partición `recovery`; parece que el recovery vive en este ramdisk. **[VERIFICAR]** cómo decide el bootloader entre arrancar Android o el recovery (parámetros añadidos en tiempo de arranque).
12. **Ninguno de los dos ramdisks trae módulos del kernel:** `cpio -t | grep -c "\.ko$"` da **0**. Coherente con la configuración del teléfono, que solo define **5** módulos (`=m`): `MSM_RDBG`, `DVB_MPQ`, `DVB_MPQ_DEMUX`, `LCD_CLASS_DEVICE`, `EXFAT_FS`; la de PixelExperience define 4 (`TCP_CONG_BIC`, `LCD_CLASS_DEVICE`, `RMNET_PERF`, `RMNET_SHS`). Ambos kernels son prácticamente **monolíticos**: casi todo está integrado en la imagen. La preocupación del Módulo 5 (#18) sobre módulos del fabricante firmados queda muy atenuada.
13. **El kernel nuevo tiene lo que necesita el arranque:** las opciones que exige ese `fstab` y Android (`BLK_DEV_DM`, `DM_VERITY`, `DM_CRYPT`, `EXT4_FS`, `F2FS_FS`, `OVERLAY_FS`, `FS_ENCRYPTION`, `ANDROID_BINDER_IPC`, `SECURITY_SELINUX`) están en `y` en `out-px/.config` y **ninguna aparece entre las 222 diferencias** con el teléfono: son iguales. Las diferencias que tocan almacenamiento son `UFSFEATURE` (solo el teléfono; función propia de Xiaomi para UFS), `EXFAT_FS` (`m` en el teléfono, integrado en PX) y `CORESIGHT` (apagado en PX). Ninguna es crítica para arrancar. **[VERIFICAR]** en el Módulo 7.

## Evidencias

**01 — Cabecera del `boot.img` (hallazgos #1 y #2)**
`header version: 3`, `os version: 12.0.0`, `os patch level: 2023-12`, `command line args:` vacío y el kernel en gzip.
![Cabecera del boot.img de fábrica, versión 3](evidencias/01-boot-cabecera-v3.png)

**02 — Receta de reconstrucción y versión del kernel de fábrica (hallazgos #3 y #4)**
`--header_version 3 … --cmdline ''` y `Linux version 4.19.157-perf-gcb1ffc010755 … clang version 10.0.7 for Android NDK, GNU ld …`.
![Receta mkbootimg y versión del kernel de fábrica](evidencias/02-kernel-fabrica-version-y-receta.png)

**03 — `vendor_boot`: DTB y línea de comandos (hallazgos #5, #6, #7 y #8)**
`VNDRBOOT`, `vendor ramdisk size: 2290`, `dtb size: 5598424`, la línea de comandos completa y los archivos `dtb` y `vendor_ramdisk`.
![vendor_boot con DTB de 5,6 MB y línea de comandos](evidencias/03-vendor-boot-dtb-y-cmdline.png)

**04 — Ramdisks: el de `vendor_boot` y el principio del de `boot` (hallazgos #10 y #11)**
`first_stage_ramdisk/fstab.default` y las primeras entradas de `boot` (`acct`, `apex`, `bin`, `first_stage_ramdisk/avb/*-gsi.avbpubkey`…); 885 entradas.
![Contenido de los dos ramdisks](evidencias/04-ramdisks-vendor-y-boot.png)

**05 — Resto del ramdisk de `boot` y cero módulos (hallazgos #11 y #12)**
`init`, `init.recovery.*.rc`, `miui.factoryreset.*` y `grep -c "\.ko$"` = 0.
![Ramdisk de boot sin módulos del kernel](evidencias/05-ramdisk-boot-contenido-y-cero-ko.png)

## Pendientes

- [x] Paso 1: `boot.img` desempaquetado, cabecera versión 3.
- [x] Paso 2: kernel de fábrica gzip (4.19.157-perf) y receta de reconstrucción.
- [x] Paso 3: `vendor_boot.img` desempaquetado: el DTB (5,6 MB) y la línea de comandos viajan ahí.
- [x] Paso 4: ramdisks listados: `vendor_boot` solo trae el `fstab`; ninguno tiene módulos `.ko`.
- [ ] Paso 5: comparación con nuestra compilación.
- [ ] Paso 6: estado de AVB en `vbmeta`.
