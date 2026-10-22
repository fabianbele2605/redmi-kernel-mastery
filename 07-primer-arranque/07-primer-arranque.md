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
# se completa con los comandos reales ejecutados
```

## Hallazgos reales

1. **La conexión se validó antes de empezar:** `adb devices` → `device`; `ro.boot.flash.locked=0`, `ro.boot.verifiedbootstate=orange`, slot `_b`, Android 13, kernel `4.19.157-perf-gcb1ffc010755`, batería 65 %, depuración USB activa. Se usó `sudo adb devices` por costumbre: no hace falta, porque el usuario ya está en `plugdev` y existe `51-android.rules`; solo había un servidor `adb`, el del usuario.

## Evidencias

(se curan con "verifica img")

## Pendientes

- [ ] Paso 1: `artifacts/boot-lab.img` construida y comprobada.
- [ ] Paso 2: teléfono en fastboot con `unlocked: yes`.
- [ ] Paso 3: `fastboot boot` probado.
- [ ] Paso 4: si arranca, `uname -r` = `4.19.297-uvite`.
- [ ] Paso 5: reinicio y regreso al kernel de fábrica.
