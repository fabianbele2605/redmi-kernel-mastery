# Módulo 14 — Más allá de Android: Linux móvil

- Estado: En progreso (investigación de compatibilidad y respaldos hechos; QEMU pendiente)
- Fecha: 2026-10-23
- Teléfono: Redmi Note 11 (`spes`), modelo `2201117TL`, variante **`spes-sm5602`** (`qcom,board-id` = `0004 0022`), kernel `4.19.297-uvite` con root de KernelSU (módulo 13, solo mientras dure el `fastboot boot`)
- Objetivo: entender el sistema completo, no solo el kernel, y averiguar **si este teléfono puede correr un Linux móvil** antes de cambiarle nada. Se hace en etapas, de menos a más riesgo, y **primero en QEMU**.

## Concepto

Android es un sistema de espacio de usuario (`system`, `vendor`, `product` dentro de la partición `super`) sobre un kernel Linux. Un «Linux móvil» (postmarketOS/Nura, Mobian, Ubuntu Touch...) sustituye ese espacio de usuario por uno basado en una distribución de escritorio (Alpine, Debian...), con una interfaz táctil (Phosh, Plasma Mobile...). Puede ir sobre el **kernel del fabricante** (el 4.19, con todos los controladores de Xiaomi pero abandonado) o sobre un **kernel principal moderno** (*mainline*), que exige que cada pieza de hardware tenga controlador en el Linux oficial.

## Práctica guiada

```bash
# Paso 1: ¿qué dice el proyecto de dispositivos? (la web esta tras un anti-bots; git si pasa)
git ls-remote https://gitlab.postmarketos.org/postmarketOS/pmaports.git HEAD
mkdir /tmp/pmaports-spes && cd /tmp/pmaports-spes && git init -q . && git remote add o https://gitlab.postmarketos.org/postmarketOS/pmaports.git
git config core.sparseCheckout true && printf 'device/*/device-xiaomi-spes/\ndevice/*/linux-xiaomi-spes/\n' > .git/info/sparse-checkout
git fetch -q --depth 1 o HEAD && git checkout -q FETCH_HEAD && find device -type f          # device/archived/...
cat device/archived/device-xiaomi-spes/{APKBUILD,deviceinfo}
grep "idVendor" device/archived/device-xiaomi-spes/deviceinfo | xxd                          # 0x05 d1 81 36: la "c" es U+0441

# Paso 2: ¿que variante es MI telefono? (con root)
adb shell 'su -c "od -An -tx1 /sys/firmware/devicetree/base/qcom,board-id"'                 # 00 04 00 22 -> spes-sm5602
adb shell getprop ro.product.model                                                          # 2201117TL

# Paso 3: mapa de particiones (solo lectura), con el tamano calculado en la laptop
adb shell 'su -c "cd /dev/block/bootdevice/by-name; for n in *; do b=\$(basename \$(readlink -f \$n)); echo \$n \$b \$(cat /sys/class/block/\$b/size); done"'

# Paso 4: respaldo de lo que no vuelve con la ROM de fabrica (solo lectura, verificado por hash)
bash artifacts/respaldar-particiones.sh                                                      # 14 OK, fallos: 0
```

## Hallazgos reales

1. **La búsqueda web estaba desactualizada.** Decía que el paquete `device-xiaomi-spes` de postmarketOS estaba en `testing`. El repositorio real (`pmaports`, commit `c7940da`, 23-oct-2026) lo tiene en **`device/archived/`**, y el `APKBUILD` de dispositivo y de kernel empiezan con **`# Archived: unmaintained`** y `maintainer=""`: archivado y sin mantenedor.
2. **postmarketOS ahora se llama «Nura»** (cambio anunciado en septiembre de 2026; sitio nuevo `nura.eco`). Las páginas oficiales antiguas redirigían a ese dominio y **no se siguió el redirect hasta confirmarlo con fuentes independientes** (Notebookcheck, Linuxiac, It's FOSS). Las referencias a «postmarketOS» persisten en paquetes y documentación.
3. **Las webs del proyecto están tras un anti-bots (Anubis)** que bloquea a las herramientas automáticas (`Making sure you're not a bot!`), y la página de paquetes daba error 500. **`git` sí pasa**: `git ls-remote` devolvió el commit, y un clon **superficial y parcial** (`sparse-checkout`, `--depth 1`) trajo solo los archivos de `spes`.
4. **El paquete archivado es de kernel de fabricante.** `linux-xiaomi-spes` 4.19.325 construido de un fork personal de GitHub (`muralivijay/kernel_xiaomi_spes`, commit `ae003d9a…`) con la configuración de `spes-perf_defconfig`; `device-xiaomi-spes` usa `fastboot`, cabecera de `boot.img` **versión 3** y `postmarketos-base-downstream`. Es de la misma familia que el kernel 4.19 que ya compilaste (el tuyo es PixelExperience 4.19.297).
5. **Un typo real en el paquete archivado:** `deviceinfo_usb_idVendor="0x05с6"` lleva una **«с» cirílica (U+0441, bytes `d1 81`)** en lugar de la `c` ASCII del identificador USB de Qualcomm (`0x05c6`). Se vio porque `xxd` mostró dos bytes donde debía haber uno; lo mismo que `ñ` en el módulo 11.
6. **La página del dispositivo en la wiki** (que pegó el usuario; está traducida por máquina y **perdió algunas etiquetas de la tabla**, así que solo se citan las que se leen con claridad): «probado con Nura, pero su paquete aún no se ha añadido a los repositorios» (no se puede elegir en `pmbootstrap`), categoría «pruebas», kernel principal **7.2.9**, con Phosh funcionando. **Funciona:** pantalla táctil, aceleración 3D (Adreno 610), Wi-Fi, Bluetooth, háptica y el módem (**llamadas, SMS y datos móviles**). **Parcial:** cámara. **Roto:** flash de cámara, infrarrojo y sensor de proximidad. **Sin aclarar por la traducción:** GPS y otros sensores. **Audio «realmente malo»:** solo el altavoz inferior y un canal auxiliar, entrecortado y con ruido. El kernel principal está en `gitlab.postmarketos.org/sm6225-mainline/kernels/linux-v.7.2.1`. Un usuario de la lista usa **/e/OS a diario y Linux en una segunda partición**.
7. **Instalación según la página (vía kernel 4.19):** `pmbootstrap export`, desempaquetar el `boot.img`, **cambiar la cabecera de versión 0 a 3**, reempaquetar, **`fastboot flash boot`**, y **`pmbootstrap flasher flash_rootfs`**. Es la primera vez en el curso que aparece `flash` en lugar de `fastboot boot`. **No se verificó a qué partición va el sistema de archivos por defecto ni si Android sigue arrancando después.**
8. **Tres variantes del Redmi Note 11, y la tuya es la mejor soportada.** La página las distingue por `qcom,board-id`: `0002 0022` (MAX77729), `0003 0022` (`spesn`, NFC), `0004 0022` (`spes-sm5602`). El teléfono tiene **`00 04 00 22`** = `spes-sm5602`, modelo `2201117TL` (está en la lista de la página). El `dmesg` lo confirma: **3 307 menciones de `sm5602`**, cargador `nopmi_chg` y `sc8551`, y `st21nfc_dev_init: not supports NFC`. La desarrolladora del puerto principal dice poder probar solo las variantes SM5602 y no la de MAX77729.
9. **Mapa de particiones** (95 entradas, A/B para `boot`, `vendor_boot`, `modem`, `dsp`, `vbmeta`, `dtbo`...). **`userdata` = 102,3 GiB** (Android y, normalmente, el sistema de Linux), **`super` = 8,5 GiB** (`system`, `vendor`, `product`), `cust` = 2 GiB, `persist` = 32 MiB. **Error del mentor:** la primera lista salió con tamaños **negativos** (`userdata -1780 MiB`) porque el `sh` de Android calcula con 32 bits; se repitió pasando los sectores crudos y calculando en la laptop.
10. **Respaldo de lo que no vuelve con la ROM de fábrica.** `artifacts/respaldar-particiones.sh` copia con `dd` (`adb exec-out`, binario sin alterar) 14 particiones propias del teléfono a `backup/particiones/` (63 MiB), y **solo acepta cada copia si el SHA-256 y el tamaño coinciden entre el teléfono y la laptop**: **14 `OK`, `fallos: 0`**. Contenido real: `modemst1`, `modemst2` y `fsg` al 99,6 % de bytes no nulos, `persist` al 2,8 %; el resto está casi vacío (menos de un 0,1 %), coherente con un teléfono restablecido de fábrica. **Esas copias contienen datos personales del teléfono (IMEI, MAC, calibraciones): `backup/` está ignorado por Git y el script se niega a ejecutarse si no lo estuviera. Solo se versiona `logs/14-hash-particiones.txt` (nombres y hashes).**
11. **Veredicto de compatibilidad.** **Apto, con límites.** A favor: bootloader desbloqueado, `boot.img` v3, `fastboot`, variante bien soportada, el módem funciona. En contra: el paquete oficial está **archivado**, el nuevo **aún no está en los repositorios**, no hay buen audio ni cámara completa, y la instalación **escribe** en el teléfono. Como teléfono de uso diario es flojo; como equipo de laboratorio, razonable.

## Evidencias

![Respaldo de 14 particiones con verificación](evidencias/01-respaldo-de-particiones.png)

Registros: `logs/14-hash-particiones.txt` (SHA-256 de las 14 copias; las copias en sí no se publican) y `artifacts/respaldar-particiones.sh`. La página de la wiki del dispositivo (`wiki.nura.eco/wiki/Xiaomi_Redmi_Note_11_(xiaomi-spes)`) se consultó en el navegador del usuario porque la herramienta automática estaba bloqueada.

## Pendientes

- [x] Compatibilidad: estado del puerto, variante propia, mapa de particiones y veredicto.
- [x] Respaldo de las particiones propias del teléfono, verificado por hash.
- [ ] **Etapa 1, en QEMU** (la guía lo pide primero): *rootfs* mínimo (BusyBox/`initramfs`) con PID 1 propio; luego un sistema tipo Alpine con servicios (OpenRC/`systemd`) y un servicio propio; empaquetar un programa; usuarios, permisos, *namespaces* y *cgroups*.
- [ ] **Etapa 3, en el teléfono sin escribir nada:** `fastboot boot` con el kernel propio y un `initramfs` propio, para tener Linux sin Android sin flashear.
- [ ] **Etapa 4, solo con confirmación explícita del usuario:** `fastboot flash`. Antes verificar a qué partición va el *rootfs*, si Android sigue arrancando, y hacer una copia fuera de la laptop de `backup/particiones/`.
- [ ] Verificar la firma PGP del kernel 6.18.58 (pendiente del módulo 11).
