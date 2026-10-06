# Curso completo de ingeniería de sistemas operativos y kernel Android

**Laboratorio:** Xiaomi Redmi Note 11 (Snapdragon 680, ARM64) · **Host:** Linux (Ubuntu/Debian) · **Lenguajes:** C y Rust · **Guía:** Claude Code en terminal

> Enfoque: 80 % práctica, 20 % teoría. Cada concepto termina en código, un experimento, una compilación o una prueba verificable. Tú escribes el código a mano para generar memoria muscular; las explicaciones son cortas y los bloques de código se explican línea por línea.

---

## 0. Ficha técnica del dispositivo

| Dato | Valor | Cómo verificarlo |
|---|---|---|
| Modelo | Redmi Note 11 (no confundir con Note 11S ni Note 11 Pro) | `adb shell getprop ro.product.model` |
| Codename | `spes` (global) / `spesn` (variante NFC) | `adb shell getprop ro.product.device` |
| SoC | Qualcomm Snapdragon 680 (SM6225), plataforma `bengal` | `adb shell getprop ro.board.platform` |
| Arquitectura | ARM64 (AArch64) | `adb shell uname -m` |
| Kernel | Serie **4.19** (Android R) | `adb shell uname -a` |
| Fuente oficial | `MiCode/Xiaomi_Kernel_OpenSource`, rama **`spes-r-oss`** | ver sección 4 |
| Base tag de la rama | `Snapdragon_Mid_2020.SPF.1.0.1R_r00024.0` | `git log -1` en el repo clonado |
| Esquema de particiones | A/B o no A/B (por confirmar) | `adb shell getprop ro.boot.slot_suffix` |

### Advertencias que afectan a todo el curso

1. **Variantes MediaTek:** el Redmi Note 11 Pro / 11S / 11 Pro+ usan otros SoC (por ejemplo `pissarro` es MediaTek). Estas fuentes **no** sirven para ellos. Confirma tu `codename` antes de clonar nada.
2. **Rust en el kernel:** el soporte de Rust en Linux llegó con kernels muy posteriores a 4.19 (a partir de la serie 6.x). El módulo en Rust se desarrolla en **QEMU con un kernel moderno**, no dentro del kernel 4.19 del teléfono, salvo que el teléfono llegue a correr un kernel mainline.
3. **Módulos (LKM) en Android:** hay que verificar en el `defconfig` de `spes` si están activos `CONFIG_MODULES`, `CONFIG_MODULE_SIG_FORCE` y `CONFIG_MODVERSIONS`. El módulo debe compilarse contra **tu** kernel compilado (el `vermagic` tiene que coincidir). Si el kernel no admite módulos externos, se integra el ejercicio dentro del árbol (`drivers/misc/`) como código built-in.
4. **El árbol de Xiaomi es *downstream*:** módulos de audio, cámara, display y otros viven en repositorios aparte. Compilar `boot.img` solo cubre el kernel.
5. **Que compile no significa que arranque**, y que arranque no significa que funcionen módem, cámara, audio o GPU.
6. **Seguridad del laboratorio (política BBLABS):** usa un teléfono **personal y aislado**: sin cuentas corporativas, sin MDM, sin datos de clientes ni credenciales. En el Bloque 2 se debilitan protecciones (por ejemplo SELinux); eso solo se hace en este equipo de laboratorio.
7. **Bootloader:** Xiaomi exige desbloqueo con su herramienta oficial (Mi Unlock), con periodo de espera, y el desbloqueo **borra los datos** del teléfono. Haz copia de seguridad antes.

---

## 1. Mapa del curso

| Fase | Módulos | Contenido | Duración |
|---|---|---|---|
| **I. Fundamentos** | 1–3 | Entorno, fundamentos de SO, C y ensamblador ARM64 | Semanas 1–6 |
| **II. Internals y programación del kernel** | 4–7 | Anatomía del kernel, memoria y concurrencia, módulos en C, Rust | Semanas 7–14 |
| **III. Android y hardware real** | 8–11 | Arranque y `boot.img`, hardware y térmica, depuración, KernelSU | Semanas 15–20 |
| **IV. Sistema operativo completo** | 12–18 | Rootfs, init, paquetes, interfaz móvil, telefonía, seguridad, distribución propia | Semanas 21–28 |

Dedicación orientativa: 6–10 horas semanales.

### Correspondencia con tus 5 bloques originales

| Bloque original | Módulos del curso |
|---|---|
| 1. Toolchain Clang/LLVM y fuentes del Redmi Note 11 | Módulo 1 |
| 2. Árbol del kernel, `.config`, seguridad/térmica, `boot.img` | Módulos 4, 8, 9 |
| 3. LKM en C con nodos `/proc` y `/sys` | Módulo 6 |
| 4. Módulo experimental en Rust | Módulo 7 |
| 5. Depuración con `dmesg`/`kmsg` y KernelSU | Módulos 10 y 11 |

---

## 2. Reglas del laboratorio

- **Git desde el día uno:** un commit por cambio, todo revisable y reversible.
- **Una variable por experimento.** Separa *medir* de *optimizar*.
- **Bitácora obligatoria** en `logs/`: comandos, salidas, errores y soluciones.
- **No flashear nada** hasta tener copia de la partición de arranque original y haber probado cómo restaurarla.
- **No empieces modificando frecuencias ni voltajes.** Primero aprende a compilar, arrancar y recuperar.
- **Nunca elimines protecciones de seguridad de batería o térmicas críticas** para conseguir más rendimiento. Los cambios térmicos se hacen medidos, de uno en uno y con reversión.
- **Primero en VM/QEMU, después en el teléfono.**

### Estructura de cada sesión

1. Teoría breve (5–10 min).
2. Lectura del código real en el árbol.
3. Escritura manual de código en C o Rust.
4. Compilación: entender cada error.
5. Prueba sin arriesgar el equipo.
6. Bitácora.

---

## 3. Fase I: Fundamentos

### Módulo 1: Entorno de desarrollo y compilación cruzada (semanas 1–2)

**Objetivo:** entorno reproducible, fuentes correctas y comprensión de cómo se genera un kernel ARM64.

| Sesión | Tema | Entrega |
|---|---|---|
| 1.1 | Preparar Ubuntu/Debian: Git, Make, GCC, Clang, LLVM, utilidades Android; comprobar espacio, RAM y arquitectura del host | Informe de versiones |
| 1.2 | Identificar la plataforma: modelo, codename, versión de Android y kernel; diferenciar ARM64 del host | Ficha técnica del teléfono |
| 1.3 | Obtener las fuentes: clonar `spes-r-oss`, registrar commit exacto, inspeccionar README/scripts | Repo descargado y bitácora |
| 1.4 | Entender LLVM y ARM64: `clang`, `ld.lld`, `llvm-ar`, `llvm-nm`; `ARCH`, `CROSS_COMPILE`, `LLVM`; compilador anfitrión frente a objetivo | Prueba de compilación cruzada |
| 1.5 | Git para kernel: ramas, commits, diffs, reversión | Primer cambio documentado y reversible |
| 1.6 | Reconocer el proceso de compilación: leer instrucciones de la rama, localizar `defconfig` | Plan de compilación reproducible |

#### 1.1 Dependencias (Debian/Ubuntu)

```bash
sudo apt update && sudo apt install -y \
  build-essential git curl wget ca-certificates bc bison flex \
  libssl-dev libelf-dev libncurses-dev dwarves \
  cpio rsync kmod xz-utils zstd lz4 unzip zip ccache \
  python3 python3-pip device-tree-compiler \
  clang lld llvm \
  gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi \
  mkbootimg android-tools-adb android-tools-fastboot
```

| Grupo | Función |
|---|---|
| `build-essential`, `bc`, `bison`, `flex` | Compilación base, cálculo de offsets, parsers de Kconfig |
| `libssl-dev`, `libelf-dev` | Firma de módulos y lectura de ELF |
| `libncurses-dev` | `make menuconfig` |
| `dwarves` | `pahole`, información de depuración/BTF |
| `cpio`, `rsync`, `kmod`, `xz-utils`, `zstd`, `lz4` | Ramdisk, instalación de módulos, compresión |
| `ccache` | Caché de compilación |
| `device-tree-compiler` | `dtc` para los Device Tree del SoC |
| `clang`, `lld`, `llvm` | Compilador, linker y utilidades LLVM |
| `gcc-aarch64-linux-gnu` | binutils/respaldo ARM64 |
| `gcc-arm-linux-gnueabi` | vDSO de 32 bits que Android exige en ARM64 |
| `mkbootimg`, `android-tools-*` | Empaquetar `boot.img`, `adb` y `fastboot` |

> Los nombres de paquete y versiones varían según la versión de la distro. Los paquetes de la distro no necesariamente coinciden con la versión de Clang que exige una rama Android antigua.

#### 1.2 Verificación de herramientas

```bash
git --version && make --version | head -1
clang --version && ld.lld --version
aarch64-linux-gnu-gcc --version | head -1
arm-linux-gnueabi-gcc --version | head -1
adb version && fastboot --version
clang --target=aarch64-linux-gnu -v
```

El último comando solo comprueba que Clang reconoce el objetivo ARM64; no demuestra que puedas compilar el kernel del teléfono.

#### 1.3 Identificar el teléfono

```bash
adb devices
adb shell getprop ro.product.model
adb shell getprop ro.product.device
adb shell getprop ro.board.platform
adb shell getprop ro.boot.slot_suffix
adb shell uname -a
```

- `adb devices`: comprueba que el host reconoce el móvil. **No publiques el número de serie.**
- `ro.product.device`: debe devolver `spes` o `spesn`.
- `ro.board.platform`: debe devolver `bengal`.
- `ro.boot.slot_suffix`: vacío si no es A/B; `_a` / `_b` si lo es.
- `uname -a`: versión del kernel en ejecución (serie 4.19).

#### 1.4 Espacio de trabajo y clonado

```bash
mkdir -p ~/lab/rn11/{src,out,artifacts,downloads,logs}
cd ~/lab/rn11
df -h "$HOME" && nproc && free -h

git clone --depth=1 --single-branch -b spes-r-oss \
  https://github.com/MiCode/Xiaomi_Kernel_OpenSource.git src/kernel
cd src/kernel
git log -1 --oneline
make -s kernelversion
```

| Línea | Explicación |
|---|---|
| `mkdir -p ... {src,out,artifacts,...}` | `src` = código; `out` = compilación fuera del árbol (el árbol queda limpio); `artifacts` = `boot.img` generados; `logs` = bitácora |
| `df -h`, `nproc`, `free -h` | Espacio libre, hilos y RAM (el árbol y los artefactos ocupan varios GB) |
| `--depth=1` | Solo el último commit: la rama tiene cientos de miles de commits |
| `--single-branch -b spes-r-oss` | Descarga solo esa rama |
| `git log -1 --oneline` | Registra el commit exacto para reproducibilidad |
| `make -s kernelversion` | Debe imprimir `4.19.x` |

Ubica el `defconfig` de `spes` (el nombre exacto se confirma en el Módulo 4):

```bash
ls arch/arm64/configs/ arch/arm64/configs/vendor/ 2>/dev/null | grep -i -E "spes|bengal"
```

#### Lista de comprobación del Módulo 1

- [ ] Identificar modelo y codename del teléfono
- [ ] Instalar herramientas
- [ ] Verificar versiones de Clang, LLVM, Git y Make
- [ ] Clonar `spes-r-oss`
- [ ] Guardar commit y salidas en la bitácora

---

### Módulo 2: Fundamentos de sistemas operativos (semanas 3–4)

**Objetivo:** entender qué problemas resuelve un kernel antes de modificar el de Android. Se hace en el PC; no requiere el teléfono.

| Sesión | Teoría | Laboratorio |
|---|---|---|
| 2.1 | Kernel frente a espacio de usuario | Documentar la ruta de una llamada al sistema |
| 2.2 | Modo usuario y modo privilegiado | Examinar syscalls con `strace` |
| 2.3 | Procesos, hilos y planificación | Programa C con varios procesos e hilos |
| 2.4 | Memoria virtual y física | Medir memoria con `/proc` |
| 2.5 | Archivos, descriptores y VFS | Lectura/escritura en C con syscalls |
| 2.6 | Interrupciones y excepciones | Analizar la ruta conceptual de una interrupción |

**Proyecto:** herramienta en C que examine procesos, memoria y llamadas al sistema en Linux.
Debes distinguir lo que hace el kernel de lo que hace `libc`.

---

### Módulo 3: C, ensamblador ARM64 y herramientas de bajo nivel (semanas 5–6)

| Sesión | Contenido | Ejercicio |
|---|---|---|
| 3.1 | Punteros, estructuras y alineación | Inspeccionar direcciones y tamaños con `sizeof` |
| 3.2 | Memoria dinámica y ciclo de vida | Analizar asignación, liberación y errores |
| 3.3 | Representación binaria y endianness | Analizador hexadecimal |
| 3.4 | Ensamblador ARM64 | Inspeccionar código generado con `llvm-objdump` |
| 3.5 | ABI, registros y llamadas a funciones | Comparar C con ensamblador |
| 3.6 | GDB, sanitizadores y depuración | Encontrar y corregir un error de memoria |

**Proyecto:** analizador de cabeceras binarias (preparación para entender la cabecera de `boot.img`).
Rust se introduce en ejercicios paralelos pequeños; C es el lenguaje de referencia para leer el kernel 4.19.

---

## 4. Fase II: Internals y programación del kernel

### Módulo 4: Anatomía y configuración del kernel (semanas 7–8) · *Bloque 2*

| Sesión | Tema |
|---|---|
| 4.1 | Árbol de fuentes: `arch/`, `kernel/`, `mm/`, `drivers/`, `fs/`, `include/` |
| 4.2 | Kconfig y `.config`: símbolos, dependencias, `make menuconfig` |
| 4.3 | Kbuild: Makefiles, `.o`, enlazado, compilación incremental frente a limpia |
| 4.4 | Inicialización del kernel (`start_kernel`) |
| 4.5 | Estructuras de datos fundamentales (listas, árboles, hash) |
| 4.6 | Código común de Linux frente a código específico de ARM64 |

**Prácticas:**
- Localizar cinco funciones y seguir sus referencias.
- Rastrear una opción desde Kconfig hasta el objeto compilado que la implementa.
- Localizar el `defconfig` de `spes` y leer sus opciones de seguridad (SELinux, módulos) y térmica.

**Primera compilación sin modificar nada.** Los kernels Android 4.19 no siempre respetan `LLVM=1` como los modernos, por lo que se fijan las variables explícitamente:

```bash
cd ~/lab/rn11/src/kernel

make O=../../out ARCH=arm64 <defconfig_de_spes>

make O=../../out ARCH=arm64 -j"$(nproc)" \
  CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm \
  OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip \
  CROSS_COMPILE=aarch64-linux-gnu- \
  CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
  CLANG_TRIPLE=aarch64-linux-gnu- \
  2>&1 | tee ~/lab/rn11/logs/build-01.log
```

| Variable | Función |
|---|---|
| `O=../../out` | Directorio de salida fuera del árbol |
| `ARCH=arm64` | Arquitectura objetivo |
| `CC=clang`, `LD=ld.lld`, `AR`, `NM`, `OBJCOPY`, `OBJDUMP`, `STRIP` | Toolchain LLVM explícita |
| `CROSS_COMPILE` | Prefijo para binutils/GCC ARM64 de respaldo |
| `CROSS_COMPILE_ARM32` | Prefijo para compilar el vDSO de 32 bits |
| `CLANG_TRIPLE` | Triple objetivo que usa Clang en kernels Android |
| `tee` | Guarda el log para la bitácora |

Si Clang de la distro es demasiado nuevo para este kernel y falla, se fija un Clang de la era Android 11 y se documenta la versión usada.

**Cambios de configuración (sin tocar nada crítico):**
1. Cambiar `CONFIG_LOCALVERSION`, recompilar y comparar la salida con `diff` del `.config`.
2. Revisar opciones de seguridad (SELinux, firma de módulos) y registrar cuáles deshabilitarías **solo en el laboratorio** y por qué.
3. Revisar parámetros térmicos en el árbol de dispositivo (`arch/arm64/boot/dts/`), pero **solo medir** hasta el Módulo 9.

**Proyecto:** documento que recorra una opción de configuración desde Kconfig hasta el objeto compilado.

---

### Módulo 5: Procesos, memoria y concurrencia dentro del kernel (semanas 9–10)

| Sesión | Concepto | Laboratorio |
|---|---|---|
| 5.1 | Estructura de procesos | Explorar `task_struct` |
| 5.2 | Planificación de CPU | Medir cambios de contexto y carga |
| 5.3 | Memoria física y virtual | Seguir páginas y asignación |
| 5.4 | Memoria del kernel | `kmalloc`, `kfree`, asignación de páginas |
| 5.5 | Concurrencia | Mutexes, spinlocks y condiciones de carrera |
| 5.6 | Sincronización y seguridad | Ejemplos de acceso concurrente y su corrección |

**Proyecto:** herramienta de observación de carga y memoria que relacione sus datos con estructuras del kernel.
Prioridad: comprender invariantes y concurrencia antes de escribir código que corre en contexto privilegiado.

---

### Módulo 6: Módulos del kernel en C (semanas 11–12) · *Bloque 3*

| Sesión | Contenido |
|---|---|
| 6.1 | Ciclo de vida: `module_init()`, `module_exit()`, metadatos y licencia; módulo frente a built-in |
| 6.2 | Compilación con Kbuild de módulos externos; compatibilidad de cabeceras, configuración y `vermagic`; `insmod`, `modprobe`, `rmmod` |
| 6.3 | Logs: `printk()`, niveles, `dmesg`, `kmsg` |
| 6.4 | `/proc` frente a `/sys`, permisos explícitos, por qué no exponer estructuras internas |
| 6.5 | Depuración de fallos y revisión de recursos |
| 6.6 | Módulo de observación de solo lectura |

**Orden de trabajo:** primero en el PC (contra el kernel de tu distro o una VM), después en el teléfono si `CONFIG_MODULES` lo permite.

#### Ejemplo base: módulo mínimo con nodo en `/proc` (kernel 4.19)

`hello_proc.c`:

```c
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>

static struct proc_dir_entry *ent;

static int hello_show(struct seq_file *m, void *v)
{
	seq_puts(m, "hola desde el kernel\n");
	return 0;
}

static int hello_open(struct inode *inode, struct file *file)
{
	return single_open(file, hello_show, NULL);
}

static const struct file_operations hello_fops = {
	.owner   = THIS_MODULE,
	.open    = hello_open,
	.read    = seq_read,
	.llseek  = seq_lseek,
	.release = single_release,
};

static int __init hello_init(void)
{
	ent = proc_create("hello_lab", 0444, NULL, &hello_fops);
	if (!ent)
		return -ENOMEM;
	pr_info("hello_lab: cargado\n");
	return 0;
}

static void __exit hello_exit(void)
{
	proc_remove(ent);
	pr_info("hello_lab: descargado\n");
}

module_init(hello_init);
module_exit(hello_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Laboratorio: nodo /proc de solo lectura");
```

Explicación por bloques:

| Parte | Qué hace |
|---|---|
| `#include <linux/...>` | Cabeceras del kernel (no `libc`): módulo, `printk`, procfs y `seq_file` |
| `static struct proc_dir_entry *ent` | Guarda el nodo creado para poder eliminarlo al descargar |
| `hello_show` | Escribe el contenido que verá `cat /proc/hello_lab` mediante `seq_file` |
| `hello_open` | Enlaza el archivo con `hello_show` usando `single_open` |
| `struct file_operations` | En **4.19** procfs usa `file_operations`; `proc_ops` aparece en kernels 5.6+ |
| `0444` | Permisos de solo lectura para todos |
| `__init` / `__exit` | Marcan funciones que se descartan tras la carga o solo existen si el módulo es descargable |
| `if (!ent) return -ENOMEM` | Manejo de error: el kernel no tolera fallos de inicialización silenciosos |
| `proc_remove(ent)` | Limpieza obligatoria; olvidarla deja un nodo huérfano y provoca fallos |
| `MODULE_LICENSE("GPL")` | Sin licencia GPL el módulo "contamina" el kernel y no puede usar símbolos GPL-only |

`Makefile` (módulo externo):

```make
obj-m += hello_proc.o

KDIR ?= ~/lab/rn11/out
all:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=arm64 \
	  CC=clang LD=ld.lld \
	  CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
```

| Línea | Explicación |
|---|---|
| `obj-m += hello_proc.o` | Declara el objeto como módulo cargable |
| `KDIR` | Directorio del kernel **ya configurado y compilado** (el `out/` del Módulo 4) |
| `-C $(KDIR) M=$(PWD)` | Entra al árbol del kernel y compila el módulo desde el directorio actual |
| `modules` | Objetivo de Kbuild que genera `hello_proc.ko` |

Prueba (primero en la VM/PC; en el teléfono, solo si el kernel admite módulos externos):

```bash
sudo insmod hello_proc.ko && cat /proc/hello_lab && sudo dmesg | tail -n 3
sudo rmmod hello_proc
```

**Ejercicios progresivos:**
1. Nodo `/proc` de solo lectura (arriba).
2. Nodo en `/sys` con `kobject` y atributos `show`/`store`.
3. Nodo que **acepta comandos** por escritura (`write`), validando longitud y contenido con `copy_from_user`.
4. Contador protegido con mutex y prueba de concurrencia.

**Proyecto:** módulo que registre inicialización y salida y exponga diagnóstico de solo lectura.
Si el kernel Android no permite módulos externos, se hace el ejercicio en VM Linux o integrado en el árbol (`drivers/misc/`). **No es necesario desactivar protecciones del teléfono para aprender.**

---

### Módulo 7: Rust dentro del kernel (semanas 13–14) · *Bloque 4*

| Sesión | Contenido | Práctica |
|---|---|---|
| 7.1 | Ownership y borrowing | Programa de gestión de recursos |
| 7.2 | `no_std` y restricciones del kernel | Diferencias con Rust de aplicación |
| 7.3 | Tipos y seguridad de memoria | Comparar la misma estructura en C y en Rust |
| 7.4 | Interoperabilidad con C: ABI, tipos, FFI | Analizar límites de FFI |
| 7.5 | Rust en Linux: Kconfig, Kbuild, ejemplos | Revisar `samples/rust/` del kernel moderno |
| 7.6 | Depuración y revisión | Evaluar errores y mantenibilidad |

**Entorno de laboratorio:** QEMU ARM64 con un kernel 6.x compilado con `CONFIG_RUST=y`.
**Proyecto:** módulo experimental en Rust que gestiona un búfer de forma segura, comparado con la versión en C.
Referencia oficial: <https://docs.kernel.org/rust/>

---

## 5. Fase III: Android y hardware real

### Módulo 8: Bootloader, arranque y `boot.img` (semanas 15–16) · *Bloque 2*

| Sesión | Tema |
|---|---|
| 8.1 | Secuencia: Boot ROM → bootloader → kernel → `init` → servicios; fallo de kernel frente a fallo de Android |
| 8.2 | Componentes: `boot.img`, `vendor_boot` (si existe), DTB/DTBO, ramdisk; versiones de cabecera |
| 8.3 | ADB frente a Fastboot; estado del bootloader, verificación (AVB) y recuperación |
| 8.4 | Analizar una imagen original |
| 8.5 | Reconstruir su estructura |
| 8.6 | Comparar el artefacto compilado con el formato exigido por el dispositivo |

**Flujo de trabajo (sin flashear aún):**

```bash
# 1) Desempaquetar tu boot.img ORIGINAL (extraído del teléfono o de tu ROM)
unpack_bootimg --boot_img boot.img --out ~/lab/rn11/artifacts/orig

# 2) Anotar versión de cabecera, cmdline, offsets y tamaño de página

# 3) Reempaquetar con TU kernel + ramdisk/DTB originales
mkbootimg --kernel <Image.gz-dtb|Image.gz> --ramdisk <ramdisk> \
  --cmdline "<cmdline original>" --header_version <N> \
  -o ~/lab/rn11/artifacts/boot-lab.img
```

- La cabecera exacta depende de la ROM instalada; **se verifica, no se asume**.
- El comando exacto de `mkbootimg` y la imagen de kernel que corresponde (con o sin DTB anexado) se confirman con los datos del `boot.img` original.
- Prueba con `fastboot boot boot-lab.img` (arranque temporal) si el bootloader lo permite, **antes** de cualquier flasheo permanente.
- Conserva copia de la imagen original y prueba el procedimiento de restauración.

**Proyecto:** generar y verificar un artefacto de kernel y documentar los pasos para integrarlo en una imagen arrancable.
Referencia: documentación de Android sobre cabeceras de `boot.img` (source.android.com).

---

### Módulo 9: Controladores, hardware, rendimiento y térmica (semanas 17–19) · *Bloque 2*

| Sesión | Tema |
|---|---|
| 9.1 | CPU y planificación: `cpufreq`, gobernadores, límites, afinidad |
| 9.2 | Modelo de dispositivos y buses, Device Tree, interrupciones; estudiar un controlador existente antes de modificarlo |
| 9.3 | GPU Adreno: frecuencia, carga, relación kernel/firmware/userspace |
| 9.4 | Energía y temperatura: sensores, `thermal_zone`, DVFS |
| 9.5 | Presión de memoria |
| 9.6 | Análisis de cuellos de botella |
| 9.7–9.9 | Diseño de pruebas A/B: configuración original frente a modificada bajo las mismas condiciones |

**Medición base (sin modificar nada):**

```bash
adb shell cat /sys/class/thermal/thermal_zone*/type
adb shell cat /sys/class/thermal/thermal_zone*/temp
adb shell cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
adb shell cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq
```

(Las rutas exactas pueden variar según el kernel; se confirman en el equipo.)

**Proyecto:** informe comparativo de rendimiento, temperatura y consumo estimado, con pruebas sostenidas (no solo benchmarks cortos).
Modificar un parámetro térmico: de uno en uno, con medición previa y posterior, y **sin desactivar protecciones críticas ni forzar voltajes inseguros**.

---

### Módulo 10: Depuración, pruebas y calidad (semana 20) · *Bloque 5, parte 1*

| Sesión | Contenido | Resultado |
|---|---|---|
| 10.1 | Logs, `dmesg`, `/proc/kmsg`, búfer circular, niveles de `printk`, trazas y símbolos | Diagnóstico documentado de un fallo de prueba |
| 10.2 | Pruebas funcionales, de estrés y regresiones | Suite reproducible |
| 10.3 | Git, parches y revisión de seguridad | Serie de parches revisables y reversibles |

**Comandos de referencia:**

```bash
adb shell dmesg | tail -n 100            # búfer circular del kernel
adb shell dmesg -w                       # seguimiento en tiempo real
adb shell cat /proc/kmsg                 # lectura del búfer (consume mensajes)
adb shell cat /proc/sys/kernel/printk    # niveles de log
```

- Distinguir kernel panic de bloqueo de userspace.
- Revisar `ramoops`/`pstore` si el kernel lo trae habilitado, para conservar el log tras un reinicio por panic.
- Identificar errores de memoria y de concurrencia.

**Proyecto:** reproducir un error controlado en el laboratorio, recopilar pruebas y demostrar que la corrección no rompe lo anterior.

---

### Módulo 11: KernelSU y análisis en vivo (semana 20 en adelante) · *Bloque 5, parte 2*

- Un kernel **4.19 no es GKI**: KernelSU requiere integrar sus hooks manualmente en el árbol. Se revisa su documentación vigente antes de empezar y se documenta cada parche.
- Observación en tiempo real con `ftrace` y `kprobes` si el `defconfig` los habilita.
- Uso responsable: solo en el teléfono de laboratorio, aislado de cuentas y datos corporativos.

---

## 6. Fase IV: Sistema operativo completo

> El curso del kernel por sí solo no cubre el *user space*. Para entender proyectos como Ubuntu Touch, Mobian o postmarketOS hay que estudiar también servicios, interfaz gráfica, red, paquetes, seguridad y aplicaciones.

### Conceptos clave

- **Kernel:** administra CPU, memoria, procesos y comunicación con el hardware.
- **Sistema operativo / distribución:** kernel + bibliotecas + servicios + herramientas + aplicaciones + experiencia de usuario.
- **Port:** adapta un sistema existente a un dispositivo específico (kernel, controladores y componentes de hardware).

### Módulo 12: Construcción del sistema raíz

- Jerarquía de archivos: `/etc`, `/usr`, `/var`, `/dev`, `/proc`.
- Bibliotecas compartidas, enlazado dinámico y ejecutables.
- Root filesystem mínimo, `chroot`, `initramfs`.
- **Proyecto:** entorno Linux mínimo que arranque en QEMU.

### Módulo 13: Inicio y servicios del sistema

- PID 1, inicialización y apagado.
- `systemd`: unidades, servicios y registros; dependencias y manejo de errores.
- **Proyecto:** sistema mínimo que arranque con un servicio propio.

### Módulo 14: Paquetes y compilación de distribuciones

- Repositorios, dependencias y paquetes binarios.
- Compilar e instalar desde código fuente; recetas de compilación; generación de imágenes.
- Debian frente a Alpine Linux.
- **Proyecto:** paquete para tu distribución de laboratorio.

### Módulo 15: Interfaz gráfica móvil

- Wayland, compositor, sesión gráfica y pantalla de bloqueo.
- Phosh, Lomiri y Plasma Mobile.
- Aplicaciones GTK o Qt adaptadas a pantalla táctil.
- **Proyecto:** ejecutar una interfaz móvil y crear una aplicación sencilla.

### Módulo 16: Red, telefonía y periféricos

- Wi-Fi, Bluetooth, USB y gestión de energía.
- ModemManager, conectividad celular y telefonía.
- Audio, cámara, sensores y firmware.
- Interfaces kernel ↔ servicios de usuario.
- **Proyecto:** documentar y probar los componentes disponibles en un dispositivo compatible.

### Módulo 17: Seguridad y aislamiento

- Usuarios, grupos, permisos y capacidades.
- Namespaces, cgroups y aislamiento de procesos.
- AppArmor, SELinux, actualizaciones y cadena de confianza.
- **Proyecto:** ejecutar una aplicación con privilegios mínimos y documentar su aislamiento.

### Módulo 18: Crear tu propia distribución

- Definir paquetes y servicios; seleccionar kernel, configuración y rootfs.
- Imágenes reproducibles, pruebas automatizadas, actualizaciones y recuperación.
- **Proyecto final:** distribución Linux experimental para QEMU y, después, port móvil si el hardware lo permite.

### Niveles de dificultad al "crear un sistema operativo"

| Objetivo | Qué construyes |
|---|---|
| Personalizar Android | Kernel, configuración, servicios o funciones de una ROM existente |
| Distribución Linux | Kernel, rootfs, paquetes, servicios y entorno de usuario |
| Sistema móvil desde Linux | Distribución + interfaz táctil + telefonía, audio, cámara y adaptación de hardware |
| Kernel desde cero | Planificador, memoria virtual, controladores y syscalls sin partir de Linux |

Recomendación: desarrolla primero una distribución pequeña y después profundiza en el kernel.

### Arquitectura por capas

| Capa | Contenido |
|---|---|
| Aplicaciones | Interfaz, terminal y apps móviles |
| Bibliotecas y servicios | libc, red, audio, telefonía, sesiones |
| Kernel Linux | Procesos, memoria, seguridad, controladores, energía |
| Hardware | CPU ARM64, GPU, pantalla, almacenamiento, radio, sensores |

En Android, componentes propietarios pueden interponerse entre el kernel y el hardware; esa es una de las dificultades de la portabilidad móvil.

### Proyectos de referencia

| Proyecto | Para qué sirve en el curso | Notas |
|---|---|---|
| **Ubuntu Touch (UBports)** | Estudiar la adaptación de Linux a teléfonos Android: kernel del dispositivo, capa Halium, rootfs Linux, entorno Lomiri | Docs: docs.ubports.com. El soporte depende del dispositivo; **verifica si `spes` está soportado** |
| **Mobian** | Distribución basada en Debian: paquetes, servicios, apps móviles | Prioriza dispositivos preparados para Linux; el soporte es específico por dispositivo |
| **Nura / postmarketOS** | Construcción de distribuciones, paquetes y adaptación a dispositivos; basada en Alpine Linux | Según la documentación revisada, Nura es el nuevo nombre de postmarketOS. **Verifícalo en nura.eco** y en su GitLab. El paquete `linux-xiaomi-spes` de postmarketOS es el fork del kernel 4.19 del Redmi Note 11 |

Ubuntu Touch y Mobian no son simplemente dos interfaces distintas sobre el mismo sistema: difieren en servicios, integración con Android, gestión de apps y adaptación del hardware.

### Orden de estudio recomendado

1. Linux en QEMU: entorno mínimo y entender el arranque sin arriesgar el teléfono.
2. postmarketOS/Nura: construcción de distribuciones, paquetes y adaptación a dispositivos.
3. Ubuntu Touch: Halium, capas de compatibilidad Android, Lomiri.
4. Kernel del Redmi Note 11 (`spes`): fuentes y configuración reales.
5. Tu propia distribución móvil: integrar, documentar limitaciones y decidir qué reutilizar.

---

## 7. Proyecto final: kernel `spes` personalizado y reproducible

**Criterio de finalización:** otra persona debe poder seguir tus instrucciones, reconstruir el artefacto y verificar el resultado sin pasos ocultos.

### Entregables

1. **Entorno reproducible:** versiones de herramientas, fuentes, commit y configuración.
2. **Análisis del kernel original:** árbol, configuración, arquitectura y dependencias.
3. **Modificación funcional:** una opción de configuración, un cambio pequeño de comportamiento o una interfaz de diagnóstico.
4. **Pruebas:** compilación, logs, pruebas funcionales y comparación con la versión original.
5. **Integración Android:** formato de imagen adecuado y procedimiento de prueba y recuperación.
6. **Documentación:** README, decisiones técnicas, limitaciones conocidas y procedimiento de reproducción.

### Orden recomendado de modificaciones

1. Cambiar una opción de configuración y comprobar su efecto.
2. Añadir mensajes de diagnóstico.
3. Crear una interfaz de solo lectura.
4. Modificar una función no crítica con pruebas.
5. Investigar un subsistema de rendimiento y justificar cualquier cambio con mediciones.
6. Integrar en una imagen adecuada y validar la recuperación **antes** de probar en el teléfono.

---

## 8. Calendario

| Semanas | Contenido |
|---|---|
| 1–2 | Entorno, fuentes y compilación cruzada (Módulo 1) |
| 3–4 | Fundamentos de sistemas operativos (Módulo 2) |
| 5–6 | C, ensamblador ARM64 y depuración (Módulo 3) |
| 7–8 | Anatomía, configuración y compilación del kernel (Módulo 4) |
| 9–10 | Procesos, memoria y concurrencia (Módulo 5) |
| 11–12 | Módulos del kernel en C (Módulo 6) |
| 13–14 | Rust (Módulo 7) |
| 15–16 | Arranque Android e imágenes (Módulo 8) |
| 17–19 | Controladores, CPU, GPU, energía y térmica (Módulo 9) |
| 20 | Depuración, pruebas y KernelSU (Módulos 10–11) |
| 21–24 | Sistema raíz, init, paquetes e interfaz (Módulos 12–15) |
| 25–28 | Telefonía, seguridad, distribución propia y proyecto final (Módulos 16–18) |

### Distribución semanal (6–10 h)

- 1 h teoría y lectura de documentación.
- 2 h lectura de código fuente.
- 3–5 h programación, compilación y experimentación.
- 1 h pruebas, documentación y revisión de Git.

Si un módulo es difícil, extiéndelo en lugar de saltar fundamentos.

---

## 9. Bibliografía y recursos

- **Linux Kernel Development**, Robert Love: procesos, planificación, memoria e interfaces (contrasta detalles con la versión real del kernel).
- **Operating Systems: Three Easy Pieces** (gratuito): virtualización, concurrencia y persistencia.
- **Documentación oficial del kernel Linux:** <https://docs.kernel.org/> (compilación con LLVM: <https://docs.kernel.org/kbuild/llvm.html>; Rust: <https://docs.kernel.org/rust/>).
- **Xiaomi Kernel OpenSource:** <https://github.com/MiCode/Xiaomi_Kernel_OpenSource> (rama `spes-r-oss`).
- **AOSP:** <https://source.android.com/> (arranque, imágenes y relación kernel ↔ sistema).
- **Git:** <https://git-scm.com/doc>.
- **UBports:** <https://docs.ubports.com/> · **Nura / postmarketOS:** <https://docs.nura.eco/>.

---

## 10. Al terminar deberías poder

- Explicar la diferencia entre kernel, sistema operativo y espacio de usuario.
- Leer código C del kernel y seguir el flujo de una función.
- Comprender procesos, memoria virtual, concurrencia e interrupciones.
- Configurar y compilar un kernel ARM64 desde las fuentes de `spes`.
- Desarrollar módulos de prueba, interpretar logs y depurar errores.
- Entender las interfaces entre Android, el kernel y el hardware.
- Evaluar cambios de rendimiento con pruebas repetibles.
- Entender qué aporta Rust y qué requisitos impone en el kernel.
- Mantener un proyecto Git documentado, revisable y reproducible.

---

## Siguiente paso

Ejecuta y pega la salida de:

```bash
adb shell getprop ro.product.model
adb shell getprop ro.product.device
adb shell getprop ro.board.platform
adb shell getprop ro.boot.slot_suffix
adb shell uname -a
cd ~/lab/rn11/src/kernel && make -s kernelversion
```

Con eso se confirma `spes` o `spesn`, si el equipo es A/B, y se arranca el Módulo 4 con la ubicación real del `defconfig`.