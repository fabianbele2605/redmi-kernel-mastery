# Módulo 7 — El primer arranque con tu kernel

- Estado: En progreso
- Fecha: 2026-10-22
- Teléfono: Redmi Note 11 `spes`, Android 13 (MIUI `V14.0.5.0.TGCMIXM`), A/B slot `_b` activo, bootloader **desbloqueado** (`ro.boot.flash.locked=0`, `verifiedbootstate=orange`), batería 65 %
- Kernel de fábrica en marcha: `4.19.157-perf-gcb1ffc010755`
- Kernel a probar: `4.19.297-uvite` (`artifacts/px/Image.gz`, hash `61ee45c3…` en `logs/05-hash-px.txt`)
- Objetivo: arrancar **una vez** el teléfono con el kernel que compilaste, sin escribir nada en sus particiones, y comprobar con `uname -r` que es el tuyo.

> ⚠️ Este es el módulo de mayor riesgo del curso. **Regla: solo `fastboot boot` (arranque temporal desde la memoria). Nunca `fastboot flash`/`erase`/`set_active`.** Si algo falla, reiniciar el teléfono devuelve el kernel de fábrica, porque ninguna partición se modifica.

## Concepto

`fastboot boot imagen` no flashea: el bootloader recibe la imagen por USB, la carga en la RAM y arranca desde ahí. Al reiniciar, vuelve a leer `boot_b` (el kernel de fábrica, intacto). Es la prueba más segura que existe.

La imagen que probamos (`boot-lab.img`) es el `boot.img` de fábrica con **una sola pieza cambiada: el kernel**. Todo lo demás se queda como está: el ramdisk de `boot`, y `vendor_boot` (DTB y línea de comandos) y `dtbo` y `vbmeta` en las particiones.

## Datos de partida (módulo 6)

- Receta (validada: reproduce el original al byte): `mkbootimg --header_version 3 --os_version 12.0.0 --os_patch_level 2023-12 --kernel <kernel> --ramdisk backup/stock-unpacked/boot/ramdisk --cmdline ''`.
- Con nuestro `Image.gz` el `boot.img` pesará 37 396 480 B (35,7 MiB), frente a 38 641 664 B el de fábrica.
- `vbmeta` cubre `boot` por hash: el de nuestra imagen **no coincidirá**. Con el bootloader desbloqueado AVB debería avisar pero dejar arrancar. **[VERIFICAR]**
- `max-download-size` del bootloader: 796 917 760 B, mucho más que 37 MB.
- Riesgos conocidos: al kernel le faltan 8 funciones propias de MIUI (módulo 5, hallazgo #23); el DTB y el `dtbo` son los de fábrica (el kernel de PixelExperience los compila distinto); el ramdisk de `boot` es de tipo «recovery en boot».

## Plan

| Paso | Qué | Toca el teléfono |
|---|---|---|
| 1 | Construir `boot-lab.img` y comprobarla en el disco | No |
| 2 | Entrar en modo fastboot y comprobar el estado (`unlocked`, slot, tamaño máximo) | Sí, solo lectura |
| 3 | `fastboot boot boot-lab.img` ⚠️ | Sí, arranque temporal |
| 4 | Si arranca: confirmar `uname -r`, `dmesg`, pantalla, táctil, Wi-Fi | Sí, solo lectura |
| 5 | Reiniciar y comprobar que vuelve el kernel de fábrica | Sí |

## Práctica guiada

```bash
# Paso 1: construir boot-lab.img (receta validada, pero con NUESTRO kernel) y comprobarla en el disco
python3 tools/mkbootimg/mkbootimg.py --header_version 3 --os_version 12.0.0 --os_patch_level 2023-12 --kernel artifacts/px/Image.gz --ramdisk backup/stock-unpacked/boot/ramdisk --cmdline '' -o artifacts/px/boot-lab.img
ls -l artifacts/px/boot-lab.img                                       # 37396480
python3 tools/mkbootimg/unpack_bootimg.py --boot_img artifacts/px/boot-lab.img --out backup/stock-unpacked/lab-check
cmp backup/stock-unpacked/lab-check/ramdisk backup/stock-unpacked/boot/ramdisk && echo "RAMDISK IGUAL AL DE FABRICA"
python3 artifacts/verificar-boot-avb.py artifacts/px/boot-lab.img     # NO coincide (esperado)
sha256sum artifacts/px/boot-lab.img | tee logs/07-hash-boot-lab.txt
```

## Hallazgos reales

1. **La conexión se validó antes de empezar:** `adb devices` → `device`; `ro.boot.flash.locked=0`, `ro.boot.verifiedbootstate=orange`, slot `_b`, Android 13, kernel `4.19.157-perf-gcb1ffc010755`, batería 65 %, depuración USB activa. Se usó `sudo adb devices` por costumbre: no hace falta, porque el usuario ya está en `plugdev` y existe `51-android.rules`; solo había un servidor `adb`, el del usuario.
2. **`boot-lab.img` construida y comprobada (Paso 1):** mide **37 396 480 bytes** (35,7 MiB de los 96 MiB de la partición: cabe de sobra), `unpack_bootimg` la lee como `ANDROID!`, `header version: 3`, `os version 12.0.0`, `os patch level 2023-12`, **`kernel_size: 17619346`** (el de nuestro `Image.gz`) y `ramdisk size: 19769994`; `cmp` confirma que el **ramdisk es idéntico** al de fábrica (`RAMDISK IGUAL AL DE FABRICA`). Solo cambió el kernel. SHA-256: `d8c3f89d2bfcc45b40e31cac38a4f2d3740c4c591958d321aff7fc2587b50806` (`logs/07-hash-boot-lab.txt`).
3. **Fallo del script `verificar-boot-avb.py` (era del mentor):** el script salía con el error `la imagen mide 37396480 bytes y vbmeta espera al menos 38641664`, porque se escribió suponiendo que la imagen nunca sería más corta que lo que declara `vbmeta`. La nuestra lo es (un kernel más pequeño). Se corrigió rellenando con ceros hasta el tamaño declarado (lo que leería AVB de una partición con relleno) y avisando de ello. Resultado tras la corrección: la imagen de fábrica **coincide** y `boot-lab.img` da `be81f7ababbc093a09b779373553b713f6a001179b9dbd09887e247755052fc0` frente a `60291945b91c009b50e0452e…`: **NO coincide**, como se esperaba. Un hash distinto es el esperado y la primera razón es obvia: la imagen mide 1 245 184 bytes menos que la original.

## Evidencias

**01 — `boot-lab.img` construida y comprobada (hallazgos #2 y #3)**
`ls -l` con 37 396 480 B, cabecera 3 con `kernel_size: 17619346`, `RAMDISK IGUAL AL DE FABRICA`, el error del script antes de corregirlo y el `sha256sum`.
![boot-lab.img construida y comprobada](evidencias/01-boot-lab-construida-y-comprobada.png)

## Pendientes

- [x] Paso 1: `artifacts/px/boot-lab.img` construida y comprobada (solo cambia el kernel; AVB no coincide, como se esperaba).
- [ ] Paso 2: teléfono en fastboot con `unlocked: yes`.
- [ ] Paso 3: `fastboot boot` probado.
- [ ] Paso 4: si arranca, `uname -r` = `4.19.297-uvite`.
- [ ] Paso 5: reinicio y regreso al kernel de fábrica.
