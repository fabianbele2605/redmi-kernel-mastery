# Laboratorio paso a paso: kernel del Redmi Note 11 (`spes`)

**Equipo:** Xiaomi Redmi Note 11 (Snapdragon 680, ARM64) · **Host:** Ubuntu/Debian · **Lenguajes:** C (principal), Rust (en QEMU)

Cómo usar esta guía:

- Se avanza **en orden**. No pases al siguiente módulo sin cumplir su **Checkpoint**.
- Cada módulo tiene: objetivo, pasos numerados, checkpoint, "si falla" y qué anotar en la bitácora.
- Donde aparece `⚠️` hay riesgo para el teléfono. Lee el módulo 3 (copias de seguridad) **antes** de llegar al módulo 7 (primer arranque).
- **El laboratorio es el teléfono.** Cada módulo termina con una prueba hecha **en el Redmi Note 11** y con su evidencia (foto o captura) en `img/`. El PC solo se usa para lo que el teléfono no puede hacer (compilar el kernel completo) y QEMU solo para lo que el kernel 4.19 del teléfono no soporta (Rust).
- Todo lo marcado **[VERIFICAR]** depende de tu equipo o de la rama exacta del kernel. No lo supongas: compruébalo y anótalo.

---

## Mapa de módulos

| # | Módulo | Toca el teléfono | Riesgo |
|---|---|---|---|
| 0 | Reglas y carpeta de trabajo | No | Ninguno |
| 1 | Preparar el PC | No | Ninguno |
| 2 | Identificar el teléfono | Solo lectura (ADB) | Ninguno |
| 3 | Copias de seguridad y recuperación | Sí (desbloqueo) | **Borra datos** |
| 4 | Descargar el kernel `spes` | No | Ninguno |
| 5 | Compilar el kernel sin modificarlo | No | Ninguno |
| 6 | Analizar el `boot.img` original | No | Ninguno |
| 7 | Armar `boot-lab.img` y arrancarlo ⚠️ | Sí | Medio |
| 8 | Depuración: logs y `pstore` | Lectura | Bajo |
| 9 | Primer módulo del kernel en C | Sí | Bajo/medio |
| 10 | Medir CPU, térmica y GPU | Lectura | Bajo |
| 11 | Rust (kernel en QEMU, programas en el teléfono) | Parcial | Ninguno |
| 12 | Cambios propios al kernel ⚠️ | Sí | Medio |
| 13 | KernelSU (opcional) ⚠️ | Sí | Medio |
| 14 | Más allá de Android: Linux móvil | Opcional | Alto |

Ruta mínima si tienes poco tiempo: **0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8**. Con eso ya compilas y arrancas tu propio kernel.

---

## Módulo 0: Reglas, repositorio y evidencias

**Objetivo:** que todo sea reproducible, reversible y esté documentado con pruebas.

**Reglas:**

1. Un cambio a la vez, cada uno con su commit.
2. No flashees nada sin tener la copia original y haber probado cómo restaurarla.
3. Antes de optimizar, mide.
4. Usa un teléfono **de laboratorio**: sin cuentas del trabajo, sin datos importantes.
5. Anota todo en `logs/` y guarda la evidencia en `img/`.

### Dónde se hace cada cosa

| Tarea | Dónde | Por qué |
|---|---|---|
| Compilar el kernel completo | PC | Necesita mucha RAM, disco y tiempo; el resultado se prueba en el teléfono |
| Todo lo demás: identificar, arrancar, leer logs, módulos, mediciones, cambios | **Teléfono** | Es el objetivo del curso |
| Práctica de C, procesos, memoria, syscalls | **Teléfono con Termux** (opcional) o PC | Termux trae `clang` para ARM64; así practicas directamente sobre el hardware real |
| Rust dentro del kernel | QEMU | El kernel 4.19 del teléfono no soporta Rust |
| Rust como programa normal | Teléfono (Termux) o PC | Es userspace, no kernel |

### Estructura del repositorio

La raíz del repositorio es `~/Escritorio/Mobil`:

```text
Mobil/
├── docs/        guías y prompt del mentor
├── img/         fotos y capturas (evidencias)
├── logs/        bitácora de cada experimento
├── artifacts/   boot-lab.img, parches, configs
├── src/         kernel (NO se sube a Git)
├── out/         compilación (NO se sube)
├── backup/      boot.img original (NO se sube)
└── downloads/   ROM de fábrica (NO se sube)
```

**Pasos:**

```bash
cd ~/Escritorio/Mobil
mkdir -p src out artifacts backup downloads logs tools img
git init 2>/dev/null || true
printf 'src/\nout/\ndownloads/\nbackup/\ntools/\n' > .gitignore
```

> `backup/` y `downloads/` quedan fuera de Git a propósito: contienen la ROM y el `boot.img` originales de Xiaomi (pesados y con derechos de autor). Solo se guardan sus **hashes** (SHA-256) en `logs/`.

### Evidencias: cómo guardar fotos y capturas

Las fotos y capturas son la prueba de que cada paso se hizo en el teléfono y sirven para los documentos finales.

**Nombre de carpeta y archivo:**

```text
img/MM-nombre-del-modulo/AAAA-MM-DD_NN_descripcion.jpg
```

Ejemplos:

```text
img/02-identificar/2025-10-05_01_getprop-spes.jpg
img/07-primer-arranque/2025-10-12_03_uname-lab01.jpg
img/07-primer-arranque/2025-10-12_04_pantalla-fastboot.jpg
```

**Qué fotografiar** (mínimo por módulo):

| Módulo | Evidencia mínima |
|---|---|
| 2 | Pantalla "Acerca del teléfono" y salida de `getprop` en la terminal |
| 3 | Pantalla de Mi Unlock con éxito y pantalla de fastboot con `unlocked: yes` |
| 5 | Terminal con el final de la compilación (`Image` generado) |
| 6 | Salida de `unpack_bootimg` con la cabecera |
| 7 | El teléfono mostrando `uname -a` con **tu** `LOCALVERSION` (foto de la pantalla) |
| 8 | `dmesg` mostrando tus mensajes |
| 9 | `dmesg` con tu módulo cargado y `cat /proc/hello_lab` |
| 10 | Gráfica o tabla de temperatura y frecuencia |
| 12 | Cada cambio funcionando antes/después |

**Reglas de las fotos:**

1. **Antes de subirlas, tapa datos personales:** número de serie, IMEI, cuenta Mi, correo, número de teléfono. Una foto con el IMEI visible no debe llegar a un repositorio público.
2. Reduce el tamaño: fotos de 5-10 MB llenan el repositorio. Con `convert` (ImageMagick): `convert foto.jpg -resize 1600x foto-peq.jpg`.
3. Una foto = un hecho. Pon en el nombre qué demuestra.
4. Cada foto se enlaza desde la bitácora (`logs/NN-*.md`) con una línea de contexto:

   ```markdown
   ![uname con LOCALVERSION](../img/07-primer-arranque/2025-10-12_03_uname-lab01.jpg)
   *El teléfono arrancó con mi kernel; `uname -r` muestra `-lab01`.*
   ```

5. Mantén un índice en `logs/evidencias.md` con fecha, módulo, archivo y qué demuestra.

### Plantilla de bitácora

Crea `logs/_plantilla.md`:

```markdown
# Experimento XX: <título>
- Fecha:
- Módulo:
- Qué intenté:
- Qué esperaba:
- Qué ocurrió (pega la salida):
- Evidencia: ![descripción](../img/MM-modulo/archivo.jpg)
- Por qué ocurrió:
- Cómo lo solucioné:
- Cómo reproducirlo / cómo revertirlo:
```

### Flujo de Git (al terminar cada paso)

```bash
git status
git add img/ logs/ docs/ artifacts/
git commit -m "modulo 05: kernel base compilado sin cambios"
```

- Un commit por paso, con el número de módulo en el mensaje.
- Las fotos se suben junto con la bitácora que las explica.
- Si quieres una copia remota, crea un repositorio **privado** en GitHub. Revisa antes que no haya datos personales en las imágenes.

**Checkpoint:** existen las carpetas, `git log` funciona y hay al menos un commit con `logs/_plantilla.md`.

---

## Módulo 1: Preparar el PC

**Objetivo:** tener las herramientas instaladas y verificadas.

**Pasos:**

1. Comprueba recursos (necesitas unos 30 GB libres y 8 GB de RAM como mínimo):

   ```bash
   df -h "$HOME"; nproc; free -h; uname -m
   ```

2. Instala dependencias:

   ```bash
   sudo apt update && sudo apt install -y \
     build-essential git curl wget ca-certificates bc bison flex \
     libssl-dev libelf-dev libncurses-dev dwarves \
     cpio rsync kmod xz-utils zstd lz4 unzip zip ccache \
     python3 python3-pip device-tree-compiler \
     clang lld llvm \
     gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi \
     android-tools-adb android-tools-fastboot \
     qemu-system-arm strace gdb
   ```

3. `mkbootimg` y `unpack_bootimg` **[VERIFICAR]**: según la distro vienen en un paquete (`mkbootimg`) o no existen. Plan B: descárgalos del repositorio de AOSP (`platform/system/tools/mkbootimg`) a `~/Escritorio/Mobil/tools/` y llámalos con `python3`.

   ```bash
   which mkbootimg unpack_bootimg || echo "usa el plan B (scripts de AOSP)"
   ```

4. Regla `udev` para ADB (si `adb devices` no te ve el teléfono): instala `android-sdk-platform-tools-common` y añade tu usuario al grupo `plugdev`:

   ```bash
   sudo apt install -y android-sdk-platform-tools-common
   sudo usermod -aG plugdev "$USER"   # cierra sesión y vuelve a entrar
   ```

5. Guarda las versiones:

   ```bash
   { git --version; make --version | head -1; clang --version | head -1; \
     ld.lld --version; aarch64-linux-gnu-gcc --version | head -1; \
     adb version | head -1; fastboot --version | head -1; } | tee logs/01-versiones.txt
   ```

**Checkpoint:** todos los comandos de la verificación responden y `logs/01-versiones.txt` existe.

**Si falla:** si falta un paquete, busca su nombre con `apt search <nombre>`; en Debian y Ubuntu a veces cambia.

---

## Módulo 2: Identificar el teléfono

**Objetivo:** confirmar que es de verdad un `spes`/`spesn`. Hay variantes del "Redmi Note 11" con otro chip (MediaTek); sus fuentes **no** sirven.

**Pasos:**

1. En el teléfono: *Ajustes → Acerca del teléfono → toca 7 veces "Versión de MIUI"* para activar opciones de desarrollador.
2. *Opciones de desarrollador →* activa **Depuración USB**. Anota también si aparece **Desbloqueo OEM** y **Desbloqueo de Mi**.
3. Conecta por USB, acepta la huella RSA en el teléfono y ejecuta:

   ```bash
   adb devices
   adb shell getprop ro.product.model
   adb shell getprop ro.product.device        # debe ser spes o spesn
   adb shell getprop ro.board.platform        # debe ser bengal
   adb shell getprop ro.build.version.release
   adb shell getprop ro.boot.slot_suffix      # vacío = no A/B; _a/_b = A/B
   adb shell uname -a                         # kernel 4.19.x
   adb shell getprop ro.boot.flash.locked     # 1 = bootloader bloqueado
   adb shell getprop ro.build.fingerprint
   ```

4. Guarda todo en `logs/02-ficha-telefono.txt` y completa esta ficha:

   ```text
   Modelo:                 Codename:
   SoC / plataforma:       Kernel:
   Android / MIUI:         A/B (slot_suffix):
   Bootloader bloqueado:   Fingerprint:
   ```

   No publiques el número de serie.

**Checkpoint:** `ro.product.device` = `spes` o `spesn` y `ro.board.platform` = `bengal`.

**Si falla:** si el codename es otro (por ejemplo `pissarro`), **detente**: esta guía no es para ese modelo.

---

## Módulo 3: Copias de seguridad y recuperación ⚠️

**Objetivo:** tener cómo volver al estado original **antes** de tocar nada. Este es el módulo más importante de la guía.

> Desbloquear el bootloader **borra todos los datos** y no se puede deshacer sin volver a bloquear. Haz antes copia de tus fotos, chats y apps.

**Pasos:**

1. **Cuenta Xiaomi y desbloqueo:**
   - Inicia sesión con tu cuenta Mi en el teléfono y vincúlala en *Opciones de desarrollador → Estado de Mi Unlock*.
   - Descarga la herramienta oficial **Mi Unlock** desde el sitio de Xiaomi. Hay un **periodo de espera** (puede ser de días) **[VERIFICAR]**; mientras tanto avanza con los módulos 4 a 6, que no necesitan el teléfono.
2. **Descarga la ROM de fábrica (fastboot ROM)** de tu modelo y la **misma versión** que tienes instalada (compara con `ro.build.fingerprint`). Guárdala en `downloads/` y anota el nombre y su hash:

   ```bash
   sha256sum downloads/*.tgz | tee logs/03-hash-rom.txt
   ```

3. **Extrae el `boot.img` original** de la ROM (`images/boot.img`) y cópialo a `backup/`. Si hay `vendor_boot.img`, `dtbo.img` y `vbmeta.img`, cópialos también:

   ```bash
   mkdir -p backup/stock && tar -xzf downloads/<rom>.tgz -C downloads/
   cp downloads/*/images/{boot,vendor_boot,dtbo,vbmeta}.img backup/stock/ 2>/dev/null
   ls -l backup/stock/
   sha256sum backup/stock/* | tee logs/03-hash-stock.txt
   ```

4. **Desbloquea** con Mi Unlock cuando termine la espera. El teléfono se reinicia a fábrica. Vuelve a activar Depuración USB.
5. **Ensaya la recuperación sin riesgo:** entra en modo fastboot y comprueba que el PC lo ve.

   ```bash
   adb reboot bootloader
   fastboot devices
   fastboot getvar all 2>&1 | tee logs/03-fastboot-getvar.txt   # revisa current-slot, unlocked, etc.
   fastboot reboot
   ```

6. **Anota el procedimiento de rescate** en `logs/03-recuperacion.md` (cópialo y pruébalo en tu cabeza antes de necesitarlo):

   ```text
   a) Bootloop tras flashear: mantener Vol- + Encendido -> fastboot.
   b) fastboot flash boot backup/stock/boot.img   (añadir _a/_b si es A/B)
   c) Si no basta: flashear la fastboot ROM completa con la herramienta
      oficial (MiFlash) o con los scripts flash_all* de la ROM.
      Cuidado: el script "flash_all_lock" vuelve a BLOQUEAR el bootloader;
      usa el que no bloquea.
   ```

**Checkpoint:** tienes `backup/stock/boot.img` con su hash, el bootloader desbloqueado y `fastboot devices` ve el teléfono.

**Si falla:** si Mi Unlock da errores, revisa la cuenta, la versión de MIUI y el cable USB. No intentes métodos no oficiales.

---

## Módulo 4: Descargar el kernel `spes`

**Objetivo:** tener el código fuente oficial y saber exactamente qué versión es.

**Pasos:**

```bash
cd ~/Escritorio/Mobil
git clone --depth=1 --single-branch -b spes-r-oss \
  https://github.com/MiCode/Xiaomi_Kernel_OpenSource.git src/kernel
cd src/kernel
git rev-parse HEAD | tee ~/Escritorio/Mobil/logs/04-commit.txt
make -s kernelversion                  # debe dar 4.19.x
```

Localiza el `defconfig` **[VERIFICAR]**:

```bash
ls arch/arm64/configs/ arch/arm64/configs/vendor/ 2>/dev/null | grep -i -E "spes|bengal"
git grep -il "spes" -- arch/arm64 | head
find . -maxdepth 3 \( -name 'README*' -o -name '*.sh' \) | sort | head -20
```

Busca también qué compilador espera la rama:

```bash
git grep -n -E "clang|CLANG_TRIPLE|CROSS_COMPILE" -- README* Makefile | head -20
```

Anota en `logs/04-notas.md`: nombre exacto del `defconfig`, scripts de compilación si existen y versión de Clang sugerida.

**Checkpoint:** `kernelversion` da 4.19.x y sabes cómo se llama el `defconfig` de `spes`.

**Si falla:** si el clonado se corta, repítelo (`git clone` con `--depth=1` es ligero pero depende de la red).

---

## Módulo 5: Compilar el kernel sin modificarlo

**Objetivo:** producir el `Image` (o `Image.gz-dtb`) de un kernel sin cambios y entender cada error.

**Pasos:**

1. Define variables para no repetir:

   ```bash
   cd ~/Escritorio/Mobil/src/kernel
   export ARCH=arm64
   OUT=~/Escritorio/Mobil/out
   MK="make O=$OUT ARCH=arm64 \
     CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm \
     OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip \
     CROSS_COMPILE=aarch64-linux-gnu- \
     CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
     CLANG_TRIPLE=aarch64-linux-gnu-"
   ```

2. Genera la configuración (usa el `defconfig` real del módulo 4):

   ```bash
   $MK <defconfig_de_spes>
   ```

3. Compila y guarda el log:

   ```bash
   time $MK -j"$(nproc)" 2>&1 | tee ~/Escritorio/Mobil/logs/05-build-01.log
   ```

4. Si termina bien, localiza los artefactos:

   ```bash
   ls -lh $OUT/arch/arm64/boot/
   ```

5. Haz una **copia del `.config`** como línea base:

   ```bash
   cp $OUT/.config ~/Escritorio/Mobil/artifacts/config-base
   ```

**Checkpoint:** existe `Image`, `Image.gz` o `Image.gz-dtb` en `out/arch/arm64/boot/`.

**Si falla (lo más común en kernels 4.19):**

- *Errores de Clang* por ser demasiado nuevo: usa un Clang de la era Android 11 (por ejemplo, el de AOSP `clang-r383902`, o Proton Clang) descargado a `tools/` y ponlo primero en el `PATH`. Anota la versión exacta.
- *Errores de `-Werror`*: no apagues todos los avisos; corrige o aísla el archivo y anótalo.
- *Faltan herramientas* (`dtc`, `pahole`, `openssl`): vuelve al módulo 1.
- Lee **el primer error**, no el último: los demás suelen ser consecuencia.

---

## Módulo 6: Analizar el `boot.img` original

**Objetivo:** entender qué contiene la imagen que el teléfono arranca hoy. Aún no flasheas.

**Pasos:**

1. Desempaqueta:

   ```bash
   cd ~/Escritorio/Mobil
   unpack_bootimg --boot_img backup/stock/boot.img --out artifacts/orig \
     | tee logs/06-boot-header.txt
   # plan B: python3 tools/unpack_bootimg.py --boot_img ... --out ...
   ls -l artifacts/orig
   ```

2. Anota del resultado: **versión de cabecera**, `cmdline`, `base`, `kernel_offset`, `ramdisk_offset`, `page_size`, y si hay DTB.
3. Comprueba cómo está empaquetado el kernel original (con o sin DTB anexado):

   ```bash
   file artifacts/orig/kernel
   ```

4. Anota si hay `vendor_boot.img` (en ese caso el ramdisk y parte de la `cmdline` viven ahí).

**Checkpoint:** puedes responder: ¿qué versión de cabecera tiene?, ¿el kernel lleva el DTB pegado?, ¿cuál es la `cmdline`?

**Si falla:** si `unpack_bootimg` no reconoce la imagen, revisa que usas la versión del script que corresponde a esa cabecera (usa la de AOSP).

---

## Módulo 7: Armar `boot-lab.img` y arrancarlo ⚠️

**Objetivo:** arrancar **tu** kernel en el teléfono de forma reversible.

**Antes de empezar:** módulo 3 completo (copia original, bootloader desbloqueado y rescate anotado). Batería por encima del 50 %.

**Pasos:**

1. Reempaqueta con **tu kernel** y el ramdisk/cmdline **originales** (los valores salen del módulo 6; cámbialos por los tuyos):

   ```bash
   mkbootimg \
     --kernel out/arch/arm64/boot/Image.gz-dtb \
     --ramdisk artifacts/orig/ramdisk \
     --cmdline "<cmdline original>" \
     --base <base> --pagesize <page_size> \
     --header_version <N> \
     -o artifacts/boot-lab.img
   ```

   Si el original llevaba DTB aparte, no uses `Image.gz-dtb`: sigue el formato que viste en el módulo 6.

2. **Arranque temporal** (no escribe nada en el teléfono). Si no funciona en tu bootloader, no pasa nada:

   ```bash
   adb reboot bootloader
   fastboot boot artifacts/boot-lab.img
   ```

3. Cuando arranque Android, comprueba que es tu kernel:

   ```bash
   adb shell uname -a              # fecha/hora de tu compilación
   adb shell cat /proc/version
   ```

4. **Solo si `fastboot boot` no es posible** y quieres flashear, hazlo en el slot correcto y con la copia a mano:

   ```bash
   fastboot flash boot artifacts/boot-lab.img     # o boot_a / boot_b si es A/B
   fastboot reboot
   ```

   Si hay problemas: `fastboot flash boot backup/stock/boot.img`.

5. Cambia `CONFIG_LOCALVERSION` (por ejemplo `-lab01`), recompila y repite el proceso para comprobar que **ves tu cambio** en `uname -a`. Ese es el primer éxito real.

**Checkpoint:** `uname -r` muestra tu `LOCALVERSION` y el teléfono sigue funcionando (al menos pantalla, táctil y ADB).

**Si falla:**

- *Se queda en el logo o reinicia sin parar:* mantén Vol- + Encendido, entra en fastboot y restaura el `boot.img` original.
- *Entra directo a fastboot:* el formato de imagen no coincide (cabecera, offsets o DTB). Vuelve al módulo 6.
- *Arranca pero algo no funciona:* pasa al módulo 8 antes de seguir cambiando cosas.

> Que compile no significa que arranque, y que arranque no significa que funcionen módem, cámara, audio ni GPU.

---

## Módulo 8: Depuración con logs y `pstore`

**Objetivo:** saber qué pasó cuando algo falla.

**Pasos:**

1. Logs del kernel:

   ```bash
   adb shell dmesg | tail -n 100
   adb shell dmesg -w                      # en tiempo real
   adb shell cat /proc/sys/kernel/printk
   ```

2. Logs de Android (userspace): `adb logcat -b all -d | tail -n 200`.
3. Revisa si tu kernel tiene `pstore`/`ramoops` para conservar el log tras un panic **[VERIFICAR]**:

   ```bash
   adb shell "ls /sys/fs/pstore 2>/dev/null"
   adb shell zcat /proc/config.gz 2>/dev/null | grep -E "PSTORE|RAMOOPS"
   ```

4. Si se reinició por un panic, mira `/sys/fs/pstore/console-ramoops*` en el siguiente arranque.
5. Guarda un `dmesg` de referencia del **kernel sin cambios** para comparar luego:

   ```bash
   adb shell dmesg > logs/08-dmesg-base.txt
   ```

**Checkpoint:** tienes un `dmesg` base guardado y sabes si `pstore` está disponible.

---

## Módulo 9: Primer módulo del kernel en C

**Objetivo:** escribir, compilar, cargar y descargar código propio dentro del kernel.

**Orden de trabajo:** el módulo se escribe en el PC, pero **se carga y se prueba en el teléfono** (paso C). Para que eso sea posible tu kernel debe tener `CONFIG_MODULES=y`; si no lo tiene, actívalo en el módulo 12 (recompilar y arrancar `boot-lab.img`) y vuelve aquí.

El paso A (probar en el PC) es **opcional**: es una red de seguridad para depurar errores de C sin riesgo para el teléfono. Si te sientes cómodo, ve directo al paso C.

**Paso A (opcional): en el PC** (compilando contra los headers de tu distro):

```bash
mkdir -p ~/Escritorio/Mobil/modulos/hello && cd ~/Escritorio/Mobil/modulos/hello
```

`hello.c` (escríbelo a mano):

```c
#include <linux/module.h>
#include <linux/kernel.h>

static int __init hello_init(void)
{
	pr_info("hello_lab: cargado\n");
	return 0;
}

static void __exit hello_exit(void)
{
	pr_info("hello_lab: descargado\n");
}

module_init(hello_init);
module_exit(hello_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Laboratorio: primer modulo");
```

`Makefile`:

```make
obj-m += hello.o
all:
	$(MAKE) -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
clean:
	$(MAKE) -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
```

```bash
sudo apt install -y linux-headers-$(uname -r)
make && sudo insmod hello.ko && sudo dmesg | tail -n 3 && sudo rmmod hello
```

> Cargar módulos en tu PC es seguro con un ejemplo mínimo, pero hazlo mejor en una VM. Un bug en un módulo puede colgar el equipo.

**Paso B: nodo `/proc` de solo lectura** (versión para kernel 4.19, que usa `file_operations`; en 5.6+ se usa `proc_ops`). Parte del código de `claude_guia.md`, Módulo 6, y añade tu propio campo (por ejemplo, un contador de lecturas).

**Paso C: en el teléfono (el paso principal).** Comprueba si lo permite:

```bash
adb shell zcat /proc/config.gz | grep -E "CONFIG_MODULES|MODULE_SIG|MODVERSIONS"
```

- Si `CONFIG_MODULES=y` y sin firma obligatoria: compila contra `out/` (tu kernel compilado) cambiando `KDIR`:

  ```make
  KDIR ?= ~/Escritorio/Mobil/out
  all:
  	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=arm64 CC=clang LD=ld.lld \
  	  CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- modules
  ```

  Carga con `adb push hello.ko /data/local/tmp/` y `adb shell su -c "insmod /data/local/tmp/hello.ko"` (requiere root, ver módulo 13). El `vermagic` debe coincidir con tu kernel.
- Si **no** admite módulos: intégralo en el árbol (`drivers/misc/`, con su `Kconfig` y `Makefile`) y recompila el kernel.

**Ejercicios progresivos:**

1. Nodo `/proc` de solo lectura.
2. Nodo en `/sys` con `kobject` y atributos `show`/`store`.
3. Nodo que acepta escritura, validando longitud con `copy_from_user`.
4. Contador protegido con mutex y prueba concurrente.

**Evidencia:** foto o captura del teléfono con `dmesg` mostrando tu módulo y la salida de `cat /proc/hello_lab`. Guárdala en `img/09-modulo-c/`.

**Checkpoint:** ves tus mensajes en `dmesg` **en el teléfono** y puedes leer tu nodo con `cat`.

**Si falla:** `Invalid module format` = `vermagic` distinto: recompila contra el mismo `out/`. `Unknown symbol` = falta una dependencia o el símbolo es GPL-only.

---

## Módulo 10: Medir CPU, térmica y GPU

**Objetivo:** tener datos antes de cambiar nada (**medir ≠ optimizar**).

**Pasos:**

1. Lectura base (sin root basta con casi todo; las rutas pueden variar **[VERIFICAR]**):

   ```bash
   adb shell 'for z in /sys/class/thermal/thermal_zone*; do echo "$(cat $z/type): $(cat $z/temp)"; done'
   adb shell cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
   adb shell 'cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq'
   adb shell 'cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_available_frequencies'
   adb shell cat /proc/meminfo | head -5
   ```

2. Haz un script en `tools/` que guarde estos datos cada 5 segundos mientras corre una carga (por ejemplo, un benchmark o un vídeo) durante **10 minutos**; los benchmarks cortos engañan.
3. Repite 3 veces y compara. Anota temperatura inicial, final y frecuencia sostenida.
4. Lee en el árbol del kernel cómo se definen las zonas térmicas (`arch/arm64/boot/dts/`) **sin modificar nada**.

**Regla de oro:** no desactives protecciones térmicas ni de batería, ni fuerces voltajes. Cualquier cambio posterior será de uno en uno, con medición antes y después, y con vuelta atrás.

**Checkpoint:** una tabla con temperatura y frecuencia sostenida de tu kernel base.

---

## Módulo 11: Rust (kernel en QEMU, programas en el teléfono)

**Objetivo:** aprender Rust en el kernel donde sí es posible. El kernel 4.19 del teléfono **no** soporta Rust; el soporte llegó con la serie 6.x.

**Pasos:**

1. **En el teléfono (Termux):** instala Rust (`pkg install rust`) y compila un programa pequeño de ownership/borrowing directamente sobre el ARM64 real. Esto es Rust normal, no kernel. Foto de la compilación en `img/11-rust/`.
2. Descarga un kernel moderno (ver <https://docs.kernel.org/rust/>) y comprueba que tu toolchain cumple:

   ```bash
   make LLVM=1 rustavailable
   ```

3. **Desde aquí, en QEMU** (el teléfono no puede ejecutar Rust en su kernel): configura `CONFIG_RUST=y`, compila para `ARCH=arm64` y arráncalo en QEMU.
4. Estudia `samples/rust/` y escribe un módulo que gestione un búfer.
5. Compáralo con la versión en C del módulo 9: qué errores de memoria evita Rust y qué sigue siendo `unsafe`.

**Checkpoint:** un módulo Rust cargado en QEMU que imprime en `dmesg`.

---

## Módulo 12: Cambios propios al kernel ⚠️

**Objetivo:** modificar el kernel de `spes` de forma segura y verificable. Cada cambio es una iteración completa: **cambiar → compilar → arrancar → comprobar → anotar**.

**Orden recomendado (de menos a más riesgo):**

1. Cambiar `CONFIG_LOCALVERSION` (ya hecho en el módulo 7).
2. Añadir un `pr_info` en un punto inofensivo y verlo en `dmesg`.
3. Añadir un nodo `/proc` de solo lectura integrado en el árbol.
4. Habilitar una opción de depuración (por ejemplo `pstore`/`ramoops`), si el hardware lo permite.
5. Modificar una función no crítica, con prueba.
6. Cualquier cambio de rendimiento, solo con mediciones del módulo 10.

**Flujo con Git** (haz esto en `src/kernel`):

```bash
git checkout -b lab/cambio-01
# edita
git add -p && git commit -m "lab: <qué y por qué>"
git format-patch -1 -o ~/Escritorio/Mobil/artifacts/patches/
```

**Checkpoint:** una serie de parches pequeños, cada uno probado en el teléfono y reversible con `git revert`.

---

## Módulo 13: KernelSU (opcional) ⚠️

**Objetivo:** tener root/observación en vivo en el teléfono de laboratorio.

- El kernel 4.19 **no es GKI**: KernelSU debe integrarse manualmente en el árbol. Lee su documentación vigente antes de empezar **[VERIFICAR]**, y aplica cada parche como un commit separado.
- Con root puedes usar `ftrace`, `kprobes` y cargar módulos (si el kernel los admite).
- Hazlo solo con el teléfono aislado: no instales apps bancarias ni cuentas personales.

**Checkpoint:** root funcional tras arrancar tu `boot-lab.img` y tu `dmesg` sigue limpio.

---

## Módulo 14: Más allá de Android: Linux móvil

**Objetivo:** entender el sistema completo, no solo el kernel. Hazlo **primero en QEMU**, después estudia el teléfono.

1. **Rootfs mínimo en QEMU:** `debootstrap` o BusyBox, `initramfs`, arranque con PID 1 propio.
2. **Servicios:** `systemd` o OpenRC; crea un servicio propio.
3. **Paquetes:** empaqueta un programa para Alpine (`apk`) o Debian (`.deb`).
4. **Interfaz:** Wayland y Phosh en QEMU.
5. **Seguridad:** usuarios, permisos, namespaces, cgroups.
6. **Casos de estudio en el teléfono:** revisa si `spes` aparece soportado en postmarketOS (`linux-xiaomi-spes`), Ubuntu Touch o Mobian, y qué funciona (pantalla, táctil, Wi-Fi, módem, cámara, audio). **[VERIFICAR]** en su documentación actual.

Tabla de seguimiento para el teléfono:

| Componente | Android original | Linux móvil | Estado |
|---|---|---|---|
| Pantalla / táctil | | | |
| Wi-Fi / Bluetooth | | | |
| Audio | | | |
| Cámara | | | |
| Módem / SIM | | | |
| GPU | | | |
| Suspensión / batería | | | |

**Checkpoint:** una mini-distribución que arranca en QEMU con un servicio propio.

---

## Proyecto final

Criterio: otra persona debe poder seguir tus notas, reconstruir el kernel y verificar el resultado **sin pasos ocultos**.

Entregables:

1. Entorno reproducible (versiones, commit, toolchain, `defconfig`).
2. Análisis del kernel original (árbol, configuración, `boot.img`).
3. Una modificación funcional pequeña (opción de configuración, mensaje de diagnóstico o nodo de solo lectura).
4. Pruebas: logs de compilación, `dmesg` antes y después, y mediciones.
5. Procedimiento de recuperación probado.
6. README con decisiones, limitaciones y cómo reproducir.

---

## Calendario sugerido (6–10 h por semana)

| Semanas | Módulos |
|---|---|
| 1 | 0, 1, 2 |
| 2 | 3 (incluye la espera del desbloqueo), 4 |
| 3–4 | 5, 6 |
| 5 | 7, 8 |
| 6–7 | 9 |
| 8 | 10 |
| 9–10 | 11 |
| 11–12 | 12, 13 |
| 13+ | 14 y proyecto final |

Si un módulo se te atasca, extiéndelo en vez de saltarlo.

---

## Lo que NO debes hacer al principio

- No flashear nada sin la copia original probada.
- No tocar frecuencias, voltajes ni protecciones térmicas.
- No cambiar varias cosas a la vez.
- No usar un teléfono con tus cuentas o datos importantes.
- No suponer rutas, nombres de `defconfig` ni versiones: **verifícalas** y anótalas.
- No usar fuentes de otro modelo (MediaTek) con este teléfono.

---

## Recursos

- Kernel de Xiaomi: <https://github.com/MiCode/Xiaomi_Kernel_OpenSource> (rama `spes-r-oss`)
- Documentación del kernel: <https://docs.kernel.org/> (LLVM: <https://docs.kernel.org/kbuild/llvm.html>; Rust: <https://docs.kernel.org/rust/>)
- Arranque y `boot.img`: <https://source.android.com/>
- postmarketOS/Nura: <https://docs.nura.eco/> · UBports: <https://docs.ubports.com/>
- Libros: *Linux Kernel Development* (Robert Love) y *Operating Systems: Three Easy Pieces* (gratis).
