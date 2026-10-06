import pypandoc, os, textwrap

md = r"""# Curso completo de desarrollo de sistemas operativos y kernel Linux/Android
## Laboratorio práctico para Xiaomi Redmi Note 11 (spes / spesn)

> **Objetivo:** aprender sistemas operativos desde sus fundamentos y terminar construyendo, modificando y depurando un sistema Linux móvil basado en un kernel real para el Redmi Note 11.
>
> **Lenguajes principales:** C primero, Rust después.
>
> **Entorno principal:** Ubuntu/Debian.
>
> **Filosofía:** teoría corta -> leer código real -> escribir código -> compilar -> probar -> medir -> documentar.

---

# 0. IMPORTANTE: identificar exactamente el teléfono

Esta guía está orientada al **Redmi Note 11 4G** con Snapdragon 680, no a todos los teléfonos que comercialmente llevan el nombre "Redmi Note 11".

La ficha oficial de Xiaomi identifica el Redmi Note 11 con Snapdragon 680, GPU Adreno 610, pantalla AMOLED 6,43" 90 Hz y Android 11/MIUI 13 en su configuración original.

Fuentes:

- Xiaomi: https://www.mi.com/co/product/redmi-note-11/specs/
- Xiaomi Kernel OpenSource: https://github.com/MiCode/Xiaomi_Kernel_OpenSource

El árbol de código abierto oficial de Xiaomi lista:

- `spes-r-oss` — Redmi Note 11 — Android R
- plataforma de referencia indicada por Xiaomi: `Snapdragon_Mid_2020.SPF.1.0.1R_r00024.0`

El nombre de dispositivo utilizado por el ecosistema de desarrollo es normalmente `spes` / `spesn`.

Antes de continuar, comprueba:

```bash
adb shell getprop ro.product.model
adb shell getprop ro.product.device
adb shell getprop ro.board.platform
adb shell getprop ro.build.version.release
adb shell uname -a
```

También puedes comprobar:

```bash
adb shell getprop | grep -E 'ro.product|ro.board|ro.build.version'
```

**No flashees nada hasta confirmar estos datos.**

---

# 1. Objetivo final del curso

Al terminar deberías poder:

1. Explicar cómo funciona un sistema operativo.
2. Programar en C para entornos de bajo nivel.
3. Comprender memoria virtual, procesos, hilos, interrupciones y syscalls.
4. Leer el árbol de código de Linux.
5. Configurar y compilar un kernel ARM64.
6. Escribir código de kernel y módulos de prueba.
7. Comprender Device Tree y controladores.
8. Analizar el arranque de Android.
9. Comprender `boot.img`, `vendor_boot`, ramdisk y DTB/DTBO.
10. Analizar CPU, GPU, memoria, energía y temperatura.
11. Introducir Rust en el desarrollo de sistemas.
12. Crear un root filesystem Linux.
13. Crear una distribución Linux mínima.
14. Comprender systemd/OpenRC y servicios.
15. Comprender paquetes y repositorios.
16. Estudiar Wayland y escritorios móviles.
17. Estudiar proyectos como Mobian, Ubuntu Touch y Nura/postmarketOS.
18. Diseñar una distribución móvil propia.
19. Portar o adaptar Linux al teléfono cuando el soporte de hardware lo permita.
20. Mantener todo el proyecto con Git y documentación reproducible.

---

# 2. Arquitectura que vamos a estudiar

La visión general será:

```text
+----------------------------------------------------+
|                    Aplicaciones                    |
+----------------------------------------------------+
|             Entorno gráfico / Shell                |
+----------------------------------------------------+
|     Servicios: red, audio, modem, sesiones...      |
+----------------------------------------------------+
|       Bibliotecas: libc, libinput, etc.            |
+----------------------------------------------------+
|              Root filesystem / /usr                |
+----------------------------------------------------+
|                 Kernel Linux                       |
| procesos | memoria | drivers | red | seguridad    |
+----------------------------------------------------+
|        Device Tree / firmware / hardware           |
+----------------------------------------------------+
|       CPU ARM64 / GPU / pantalla / sensores        |
+----------------------------------------------------+
```

En Android la arquitectura real es más compleja. Puede haber componentes propietarios, HAL, firmware y capas de compatibilidad Android.

La meta no es reemplazar todo de golpe. La estrategia será sustituir y comprender una capa cada vez.

---

# 3. Plan general

## Fase I — Fundamentos

### Módulo 1 — Linux como sistema operativo
- Kernel vs user space
- Procesos
- Memoria
- Syscalls
- Archivos
- Dispositivos
- Interrupciones
- Seguridad

### Módulo 2 — C para sistemas
- Punteros
- structs
- memoria
- ABI
- ELF
- procesos
- hilos
- IPC
- señales
- sockets

### Módulo 3 — ARM64 y herramientas
- registros
- instrucciones
- stack
- calling convention
- ensamblador
- ELF
- objdump
- readelf
- GDB

---

## Fase II — Kernel

### Módulo 4 — Anatomía de Linux
- `arch/`
- `kernel/`
- `mm/`
- `drivers/`
- `fs/`
- `net/`
- `include/`
- Kconfig
- Kbuild

### Módulo 5 — Procesos y memoria
- scheduler
- `task_struct`
- memoria virtual
- páginas
- slab/slub
- locks
- concurrencia

### Módulo 6 — Primer código del kernel
- módulos
- printk
- dmesg
- procfs
- sysfs
- workqueues
- timers
- APIs del kernel

### Módulo 7 — Controladores
- Device Tree
- buses
- GPIO
- I2C
- SPI
- IRQ
- regulators
- clocks
- drivers

### Módulo 8 — Rust en Linux
- `no_std`
- ownership
- borrowing
- FFI
- Kbuild
- Rust-for-Linux
- límites entre Rust y C

---

## Fase III — Android móvil

### Módulo 9 — Boot Android
- Boot ROM
- bootloader
- kernel
- init
- ramdisk
- boot.img
- vendor_boot
- DTB
- DTBO
- AVB

### Módulo 10 — Hardware del Redmi Note 11
- Snapdragon 680 / SM6225
- CPU
- GPU
- pantalla
- touch
- almacenamiento
- USB
- sensores
- audio
- cámaras
- modem
- Wi-Fi/Bluetooth
- energía

### Módulo 11 — Rendimiento
- cpufreq
- CPU governors
- GPU frequency
- thermal
- RAM
- I/O
- scheduler
- medición
- benchmarking

### Módulo 12 — Depuración
- dmesg
- kmsg
- pstore
- ramoops
- crash analysis
- kernel panic
- logs de Android
- regresiones

---

## Fase IV — Crear un sistema operativo Linux

### Módulo 13 — Root filesystem
- `/bin`
- `/sbin`
- `/etc`
- `/dev`
- `/proc`
- `/sys`
- `/run`
- `/usr`
- `/var`
- initramfs

### Módulo 14 — Init y servicios
- PID 1
- systemd
- OpenRC
- servicios
- dependencias
- logs
- shutdown

### Módulo 15 — Paquetes
- Debian
- Alpine
- APK
- `.deb`
- repositorios
- dependencias
- compilación desde fuente

### Módulo 16 — Red y dispositivos
- NetworkManager
- Wi-Fi
- Bluetooth
- USB
- modem
- ModemManager
- audio
- sensores

### Módulo 17 — Interfaz móvil
- Wayland
- compositor
- GTK
- Qt
- Phosh
- Lomiri
- Plasma Mobile
- teclado
- touch
- orientación

### Módulo 18 — Seguridad
- usuarios
- grupos
- permisos
- capabilities
- namespaces
- cgroups
- AppArmor
- SELinux
- sandboxing
- actualización segura

---

## Fase V — Linux móvil

### Módulo 19 — Mobian
Estudiar:

- Debian
- kernel
- device tree
- paquetes
- Phosh
- servicios
- soporte de hardware

https://mobian-project.org/

### Módulo 20 — Ubuntu Touch / UBports
Estudiar:

- Ubuntu Touch
- Lomiri
- portabilidad
- Halium
- integración con hardware Android
- sistema raíz
- aplicaciones

https://ubports.com/

### Módulo 21 — Nura / postmarketOS
Estudiar:

- Alpine Linux
- APK
- init
- mainline Linux
- downstream kernels
- Device Tree
- ports
- Phosh/Plasma/Lomiri
- integración móvil

https://nura.eco/

Documentación técnica:

https://docs.nura.eco/

---

# 4. Módulo 1 — Preparar Ubuntu/Debian

## 4.1 Actualizar el sistema

```bash
sudo apt update
sudo apt upgrade
```

## 4.2 Instalar herramientas

```bash
sudo apt install -y \
    git curl wget ca-certificates \
    build-essential \
    bc bison flex \
    libssl-dev libelf-dev \
    libncurses-dev \
    dwarves \
    python3 python3-pip \
    unzip zip xz-utils \
    clang llvm lld \
    device-tree-compiler \
    adb fastboot \
    ccache \
    rsync
```

Comprobar:

```bash
git --version
gcc --version
clang --version
ld.lld --version
make --version
python3 --version
adb version
fastboot --version
```

---

# 5. Crear el laboratorio

```bash
mkdir -p ~/kernel-lab/{src,build,downloads,tools,logs,images}
cd ~/kernel-lab
```

Estructura:

```text
kernel-lab/
├── build/
├── downloads/
├── images/
├── logs/
├── src/
└── tools/
```

Comprobar:

```bash
pwd
df -h
nproc
free -h
```

---

# 6. Git

Configura Git:

```bash
git config --global user.name "TU_NOMBRE"
git config --global user.email "TU_EMAIL"
```

Comprueba:

```bash
git config --global --list
```

Para cada modificación importante:

```bash
git status
git diff
git add .
git commit
```

Nunca trabajes sin saber qué commit estás modificando.

---

# 7. Obtener el kernel oficial

Para el Redmi Note 11:

```bash
cd ~/kernel-lab/src

git clone \
    --branch spes-r-oss \
    --single-branch \
    https://github.com/MiCode/Xiaomi_Kernel_OpenSource.git \
    kernel-spes
```

Entrar:

```bash
cd ~/kernel-lab/src/kernel-spes
```

Comprobar:

```bash
git status
git branch
git log -1 --oneline
```

Guardar información:

```bash
git rev-parse HEAD > ~/kernel-lab/logs/kernel-commit.txt
```

La fuente oficial de Xiaomi identifica `spes-r-oss` como Redmi Note 11 / Android R.

Repositorio:

https://github.com/MiCode/Xiaomi_Kernel_OpenSource

---

# 8. Explorar el kernel

```bash
cd ~/kernel-lab/src/kernel-spes

ls
```

Después:

```bash
find arch -maxdepth 2 -type d | head -50
```

```bash
ls kernel
ls mm
ls drivers
ls fs
ls net
ls include
```

Aprenderás:

```text
arch/       -> arquitectura
kernel/     -> núcleo del kernel
mm/         -> memoria
drivers/    -> controladores
fs/         -> sistemas de archivos
net/        -> red
include/    -> headers
```

---

# 9. Entender ARM64

El Redmi Note 11 utiliza una plataforma Qualcomm Snapdragon 680.

El ordenador puede ser x86_64 mientras el kernel objetivo es ARM64:

```text
PC
x86_64
   |
   | compilación cruzada
   v
Teléfono
ARM64
```

Verifica el ordenador:

```bash
uname -m
```

Verifica Clang:

```bash
clang --version
```

Prueba:

```bash
clang --target=aarch64-linux-gnu -v
```

---

# 10. Módulo 2 — Fundamentos de Linux

Antes de modificar el teléfono, aprender:

## Procesos

```bash
ps aux
```

```bash
cat /proc/1/status
```

```bash
cat /proc/meminfo
```

```bash
cat /proc/cpuinfo
```

## Syscalls

En Ubuntu:

```bash
strace ls
```

Concepto:

```text
programa C
    |
    v
libc
    |
    v
syscall
    |
    v
kernel
    |
    v
hardware
```

Proyecto:

Crear un programa C que:

1. abra un archivo;
2. escriba datos;
3. lea datos;
4. obtenga información con `stat`;
5. cree un proceso;
6. espere al proceso hijo.

---

# 11. Módulo 3 — C de bajo nivel

Estudiar:

```c
int
char
long
size_t
uintptr_t
struct
union
enum
pointer
function pointer
```

Ejercicio:

```c
#include <stdio.h>
#include <stdint.h>

struct cpu_info {
    uint32_t id;
    uint64_t frequency;
};

int main(void)
{
    struct cpu_info cpu = {
        .id = 0,
        .frequency = 2400000000ULL
    };

    printf("CPU: %u\n", cpu.id);
    printf("Frequency: %lu\n", cpu.frequency);

    return 0;
}
```

Compilar:

```bash
gcc -Wall -Wextra -O2 cpu.c -o cpu
```

Estudiar:

```bash
file cpu
readelf -h cpu
objdump -d cpu
```

---

# 12. Módulo 4 — ARM64

Aprender:

- registros
- stack pointer
- program counter
- instrucciones
- llamadas
- retorno
- ABI
- alineación
- memoria

Compilar C a ensamblador:

```bash
clang -S -O2 programa.c -o programa.s
```

Para ARM64:

```bash
clang \
    --target=aarch64-linux-gnu \
    -S \
    -O2 \
    programa.c \
    -o programa-arm64.s
```

Estudiar el resultado manualmente.

---

# 13. Módulo 5 — Kernel internals

Leer:

```text
arch/arm64/
kernel/
mm/
drivers/
fs/
net/
include/
```

Aprender a usar:

```bash
grep
find
rg
git grep
ctags
```

Ejemplos:

```bash
git grep "SYSCALL_DEFINE"
```

```bash
git grep "printk"
```

```bash
git grep "struct task_struct"
```

Objetivo:

Poder encontrar una función dentro del kernel sin depender de copiar código de Internet.

---

# 14. Módulo 6 — Configuración

Buscar configuraciones:

```bash
find . -name '*defconfig' | head -50
```

Buscar referencias a `spes`:

```bash
git grep -i "spes"
```

Buscar configuración:

```bash
git grep "CONFIG_"
```

Estudiar:

```text
Kconfig
Makefile
Kbuild
defconfig
.config
```

Concepto:

```text
Kconfig
   |
   v
.config
   |
   v
Kbuild
   |
   v
.c -> .o -> vmlinux/Image
```

No cambies muchas opciones a la vez.

---

# 15. Módulo 7 — Compilación del kernel

Primero inspeccionar cualquier script de compilación proporcionado por el árbol:

```bash
find . -maxdepth 3 -type f \
    \( -name '*.sh' -o -name 'README*' \) \
    | sort
```

Buscar instrucciones:

```bash
git grep -n "CROSS_COMPILE"
git grep -n "CLANG"
git grep -n "LLVM"
git grep -n "defconfig"
```

No asumir una versión de Clang.

Para un kernel moderno, Linux documenta:

```bash
make LLVM=1 ARCH=arm64
```

Pero una rama Android antigua puede requerir herramientas diferentes.

Por eso el procedimiento definitivo se obtiene del árbol concreto.

---

# 16. Build separado

Cuando la rama lo permita:

```bash
mkdir -p ~/kernel-lab/build/spes
```

Conceptualmente:

```bash
make \
    O=~/kernel-lab/build/spes \
    ARCH=arm64 \
    ...
```

`O=` mantiene separados los archivos generados de las fuentes.

Esto facilita:

- limpiar builds;
- comparar configuraciones;
- mantener varias configuraciones;
- evitar contaminar Git.

---

# 17. Módulo 8 — Primer módulo del kernel

Primero practicar en una máquina Linux o VM.

Ejemplo conceptual:

```c
#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>

static int __init hello_init(void)
{
    pr_info("kernel-lab: module loaded\n");
    return 0;
}

static void __exit hello_exit(void)
{
    pr_info("kernel-lab: module unloaded\n");
}

module_init(hello_init);
module_exit(hello_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("kernel-lab");
MODULE_DESCRIPTION("First kernel module");
```

Kbuild:

```make
obj-m += hello.o
```

Compilar contra el kernel correspondiente:

```bash
make -C /lib/modules/$(uname -r)/build M=$PWD modules
```

Probar:

```bash
sudo insmod hello.ko
dmesg | tail
sudo rmmod hello
dmesg | tail
```

**No usar este bloque directamente contra el kernel del Redmi Note 11 sin adaptar la configuración, headers y toolchain.**

---

# 18. Módulo 9 — procfs y sysfs

Estudiar:

```text
/proc
/sys
```

Diferencia conceptual:

`procfs`:

```text
información del kernel/procesos
```

`sysfs`:

```text
representación de dispositivos y atributos del modelo de dispositivos
```

Proyecto:

Crear una interfaz de solo lectura que muestre:

```text
kernel-lab/version
kernel-lab/build
kernel-lab/status
```

Regla:

No crear interfaces de escritura para modificar hardware hasta entender permisos, concurrencia, validación y recuperación.

---

# 19. Módulo 10 — Procesos y scheduler

Estudiar:

```text
task_struct
scheduler
runqueue
context switch
priority
affinity
```

En user space:

```bash
ps -eLf
```

```bash
top
```

```bash
taskset -c 0 sleep 10
```

Objetivo:

Entender primero qué ocurre antes de tocar gobernadores de CPU.

---

# 20. Módulo 11 — Memoria

Estudiar:

```text
virtual memory
physical memory
pages
page tables
TLB
slab/slub
kmalloc
vmalloc
```

Linux:

```bash
cat /proc/meminfo
```

```bash
free -h
```

```bash
vmstat
```

En el kernel estudiar las APIs correspondientes a la versión concreta.

Proyecto:

Documentar el recorrido:

```text
malloc()
   |
   v
libc
   |
   v
syscall / allocator
   |
   v
kernel memory subsystem
   |
   v
physical pages
```

---

# 21. Módulo 12 — Concurrencia

Estudiar:

```text
race condition
mutex
spinlock
atomic
wait queue
completion
RCU
```

Crear ejemplos de condiciones de carrera en user space primero.

Después estudiar cómo el kernel las evita.

Regla:

No modificar código concurrente del kernel hasta poder explicar qué protege cada lock.

---

# 22. Módulo 13 — Device Tree

Estudiar:

```text
DTS
DTSI
DTB
DTBO
```

Concepto:

```text
Device Tree
     |
     v
describe hardware
     |
     v
kernel driver
     |
     v
hardware
```

Buscar:

```bash
find arch/arm64 -type f \
    \( -name '*.dts' -o -name '*.dtsi' \) \
    | head -100
```

Buscar `spes`:

```bash
git grep -i "spes" -- '*.dts' '*.dtsi'
```

---

# 23. Módulo 14 — Drivers

Estudiar progresivamente:

1. platform driver
2. GPIO
3. I2C
4. SPI
5. IRQ
6. regulator
7. clock
8. thermal
9. power
10. input
11. display
12. audio

No escribir primero un driver complejo.

Primero:

```text
leer driver existente
      |
      v
identificar probe()
      |
      v
identificar recursos
      |
      v
identificar callbacks
      |
      v
crear driver mínimo de laboratorio
```

---

# 24. Módulo 15 — Android boot

Estudiar:

```text
Boot ROM
   |
Bootloader
   |
AVB / verified boot
   |
boot image
   |
kernel
   |
ramdisk
   |
init
   |
Android userspace
```

Estudiar también:

```text
boot.img
vendor_boot.img
dtb
dtbo
vbmeta
```

La estructura exacta depende de la versión de Android y de la implementación del dispositivo.

---

# 25. Extraer información del teléfono

Con ADB:

```bash
adb shell getprop > ~/kernel-lab/logs/getprop.txt
```

```bash
adb shell uname -a \
    > ~/kernel-lab/logs/uname.txt
```

```bash
adb shell cat /proc/cpuinfo \
    > ~/kernel-lab/logs/cpuinfo.txt
```

```bash
adb shell cat /proc/meminfo \
    > ~/kernel-lab/logs/meminfo.txt
```

Guardar:

```bash
adb shell ls -la /sys/devices/system/cpu \
    > ~/kernel-lab/logs/cpu-sysfs.txt
```

---

# 26. Módulo 16 — CPU y rendimiento

Estudiar:

```text
cpufreq
CPU policy
governor
frequency
thermal throttling
scheduler
idle states
```

Explorar:

```bash
adb shell ls /sys/devices/system/cpu/
```

```bash
adb shell find /sys/devices/system/cpu \
    -maxdepth 3 -type f \
    | grep -E 'cpufreq|scaling' \
    | head -100
```

Nunca asumir que una ruta existe en todas las ROM.

Primero descubrir:

```bash
find
cat
ls
```

Después modificar.

---

# 27. Módulo 17 — GPU

Estudiar:

```text
Adreno
GPU driver
frequency
devfreq
thermal
memory bandwidth
```

Objetivo:

Comprender:

```text
application
   |
graphics API
   |
userspace driver
   |
kernel driver
   |
GPU
```

No empezar con overclock.

Primero medir:

```text
frecuencia
temperatura
carga
fps
consumo
estabilidad
```

---

# 28. Módulo 18 — Thermal

Estudiar:

```text
thermal zones
thermal sensors
cooling devices
trip points
throttling
```

Explorar:

```bash
adb shell find /sys/class/thermal -maxdepth 2 -type f
```

Regla de seguridad:

**Nunca eliminar límites térmicos para conseguir rendimiento.**

El objetivo académico es entender cómo funciona la protección térmica y cómo medir sus efectos.

---

# 29. Módulo 19 — RAM e I/O

Estudiar:

```text
page cache
reclaim
swap
zram
I/O scheduler
block layer
```

Explorar:

```bash
adb shell cat /proc/meminfo
```

```bash
adb shell cat /proc/swaps
```

```bash
adb shell cat /proc/diskstats
```

Proyecto:

Comparar dos configuraciones sin cambiar múltiples variables simultáneamente.

---

# 30. Módulo 20 — Rust

Primero Rust normal:

```bash
cargo new rust-lab
cd rust-lab
cargo run
```

Estudiar:

```text
ownership
borrowing
lifetimes
traits
enums
Result
Option
generics
concurrency
unsafe
FFI
```

Después estudiar Rust en Linux:

https://docs.kernel.org/rust/

Concepto:

```text
Rust
  |
  | FFI
  v
C / kernel APIs
  |
  v
Linux kernel
```

No asumir que cualquier kernel Android antiguo puede compilar Rust moderno.

---

# 31. Módulo 21 — Root filesystem

Crear un laboratorio separado.

Estructura mínima:

```text
rootfs/
├── bin/
├── dev/
├── etc/
├── proc/
├── sys/
├── run/
├── tmp/
├── usr/
└── var/
```

Aprender:

```text
init
busybox
libc
dynamic linker
/dev
/proc
/sys
```

Objetivo:

Crear un Linux mínimo que arranque en QEMU.

---

# 32. Módulo 22 — Init

Estudiar PID 1.

Flujo:

```text
kernel
  |
  v
/init
  |
  +--> mount /proc
  +--> mount /sys
  +--> mount /dev
  +--> start services
```

Comparar:

```text
BusyBox init
systemd
OpenRC
```

Proyecto:

Crear un servicio sencillo que arranque automáticamente.

---

# 33. Módulo 23 — Paquetes y distribución

Estudiar:

```text
Debian .deb
Alpine .apk
repositories
dependencies
package metadata
build recipes
```

Objetivo:

Crear un paquete sencillo desde código fuente.

---

# 34. Módulo 24 — Red

Estudiar:

```text
kernel networking
socket
TCP/IP
Wi-Fi
Bluetooth
NetworkManager
ModemManager
```

Proyecto:

Crear un servicio que consulte el estado de red y exponga información.

---

# 35. Módulo 25 — Audio

Estudiar:

```text
ALSA
PipeWire
PulseAudio
codec
DSP
```

Entender:

```text
application
    |
PipeWire
    |
ALSA
    |
kernel driver
    |
codec
```

---

# 36. Módulo 26 — Pantalla e interfaz

Estudiar:

```text
DRM/KMS
Wayland
compositor
input
touchscreen
GTK
Qt
```

Entornos móviles para estudiar:

```text
Phosh
Lomiri
Plasma Mobile
```

Proyecto:

Ejecutar una sesión gráfica móvil en un entorno Linux compatible.

---

# 37. Módulo 27 — Seguridad

Estudiar:

```text
users
groups
permissions
capabilities
namespaces
cgroups
SELinux
AppArmor
sandbox
verified boot
signed updates
```

Objetivo:

Comprender por qué una modificación del kernel puede afectar toda la cadena de confianza.

---

# 38. Módulo 28 — Mobian

Estudiar como caso de arquitectura:

```text
Debian
  |
kernel
  |
device support
  |
services
  |
Phosh
  |
applications
```

Web:

https://mobian-project.org/

Investigar:

- dispositivos soportados;
- kernel;
- device trees;
- paquetes;
- servicios;
- entorno gráfico;
- telefonía.

No asumir que el Redmi Note 11 funciona completamente con Mobian solo porque el kernel compile.

---

# 39. Módulo 29 — Ubuntu Touch / UBports

Estudiar:

```text
Ubuntu Touch
    |
Lomiri
    |
system services
    |
Halium / hardware integration
    |
kernel
    |
device
```

Web:

https://ubports.com/

Documentación:

https://docs.ubports.com/

Aprender:

- porting;
- Halium;
- device tree;
- kernel;
- vendor;
- Android compatibility;
- hardware bring-up.

---

# 40. Módulo 30 — Nura / postmarketOS

Estudiar:

```text
Alpine Linux
    |
apk
    |
init
    |
Linux kernel
    |
device port
    |
Phosh / Plasma / Lomiri
```

Web:

https://nura.eco/

Documentación:

https://docs.nura.eco/

Código histórico/proyecto:

https://gitlab.postmarketos.org/postmarketOS

Conceptos importantes:

```text
mainline kernel
downstream kernel
device port
firmware
hardware enablement
```

---

# 41. Módulo 31 — Crear tu propia mini-distribución

Objetivo:

```text
MiLinux
 |
 +-- Linux kernel
 |
 +-- rootfs
 |
 +-- init
 |
 +-- libc
 |
 +-- package system
 |
 +-- services
 |
 +-- UI
 |
 +-- applications
```

Primero ejecutar en QEMU.

Después estudiar qué componentes serían necesarios para un teléfono.

---

# 42. Módulo 32 — Port móvil

Este es el nivel avanzado.

Investigar:

```text
bootloader
kernel
device tree
firmware
vendor
HAL
display
touch
audio
camera
modem
Wi-Fi
Bluetooth
GPS
sensors
power
thermal
```

Orden recomendado:

1. boot;
2. consola/logs;
3. almacenamiento;
4. pantalla;
5. touch;
6. USB;
7. Wi-Fi;
8. Bluetooth;
9. audio;
10. sensores;
11. cámara;
12. modem;
13. energía;
14. suspensión;
15. aceleración gráfica.

No intentar habilitar todo a la vez.

---

# 43. Proyecto final

Crear:

## `RedmiLinux`

Un proyecto experimental cuyo objetivo sea:

```text
Redmi Note 11
      |
      v
Kernel Linux personalizado
      |
      v
Root filesystem
      |
      v
Servicios
      |
      v
Interfaz móvil
      |
      v
Aplicaciones
```

El proyecto tendrá:

```text
redmilinux/
├── kernel/
├── device/
├── rootfs/
├── packages/
├── scripts/
├── docs/
├── configs/
└── tests/
```

---

# 44. Reglas del proyecto

## Regla 1

Un cambio por commit.

## Regla 2

Una variable modificada por experimento.

## Regla 3

Medir antes y después.

## Regla 4

Mantener siempre una configuración funcional.

## Regla 5

No modificar seguridad o thermal limits sin entender las consecuencias.

## Regla 6

Primero probar en QEMU cuando sea posible.

## Regla 7

No flashear imágenes que no hayan sido verificadas.

## Regla 8

Mantener backups de las imágenes originales.

---

# 45. Git workflow

Crear ramas:

```bash
git checkout -b lab/module-01
```

Después:

```bash
git status
git diff
git add .
git commit -m "lab: prepare kernel environment"
```

Crear una rama experimental:

```bash
git checkout -b experiment/cpufreq-study
```

Volver:

```bash
git checkout main
```

Comparar:

```bash
git diff main..experiment/cpufreq-study
```

---

# 46. Estructura de documentación

Cada experimento debe tener:

```text
docs/
├── hardware.md
├── toolchain.md
├── build.md
├── boot.md
├── kernel.md
├── performance.md
├── thermal.md
├── debugging.md
└── experiments/
```

Cada experimento:

```markdown
# Experimento X

## Hipótesis

## Configuración original

## Cambio realizado

## Comandos

## Resultado

## Logs

## Medición

## Conclusión

## Cómo revertir
```

---

# 47. Checklist de recuperación

Antes de modificar el teléfono:

- [ ] Bootloader entendido
- [ ] Método de recuperación conocido
- [ ] Firmware original disponible
- [ ] Copias de seguridad
- [ ] Configuración original guardada
- [ ] Commit original guardado
- [ ] Imagen funcional disponible
- [ ] Cable USB fiable
- [ ] ADB funcionando
- [ ] Fastboot funcionando
- [ ] Procedimiento de restauración probado/documentado

---

# 48. Lo que NO debes hacer al principio

No empezar por:

```text
overclock
undervolt
desactivar thermal
desactivar SELinux
cambiar voltajes
modificar particiones sin backup
flashear kernels desconocidos
```

Primero:

```text
entender
compilar
medir
modificar
probar
revertir
```

---

# 49. Ruta de aprendizaje de C y Rust

## C

Prioridad alta:

```text
punteros
structs
arrays
memoria
bit operations
function pointers
concurrencia
syscalls
ABI
```

## Rust

Prioridad media al principio:

```text
ownership
borrowing
lifetimes
traits
Result
Option
unsafe
FFI
concurrency
no_std
```

Orden:

```text
C
 |
 +--> Linux internals
 |
 +--> kernel programming
 |
 +--> drivers
 |
Rust
 |
 +--> sistemas
 |
 +--> FFI
 |
 +--> Rust-for-Linux
```

---

# 50. Resultado esperado

Al terminar el recorrido tendrás tres proyectos relacionados pero distintos:

## Proyecto A — Kernel

```text
Linux kernel
   |
custom configuration
   |
custom code
   |
ARM64 build
```

## Proyecto B — Sistema operativo

```text
kernel
+
rootfs
+
init
+
services
+
packages
```

## Proyecto C — Sistema móvil

```text
kernel
+
device support
+
firmware
+
services
+
mobile UI
+
applications
```

La diferencia es fundamental:

**Personalizar un kernel no equivale a crear un sistema operativo.**

Un sistema operativo móvil completo requiere muchas capas por encima del kernel.

---

# 51. Orden exacto recomendado

```text
01 Ubuntu/Debian
        ↓
02 C
        ↓
03 Linux user space
        ↓
04 ARM64
        ↓
05 Linux kernel source
        ↓
06 Kconfig/Kbuild
        ↓
07 kernel modules
        ↓
08 processes/memory
        ↓
09 concurrency
        ↓
10 Device Tree
        ↓
11 drivers
        ↓
12 Android boot
        ↓
13 Redmi Note 11 kernel
        ↓
14 CPU/GPU/thermal
        ↓
15 Rust
        ↓
16 root filesystem
        ↓
17 init/services
        ↓
18 packages
        ↓
19 Wayland/mobile UI
        ↓
20 Mobian
        ↓
21 Ubuntu Touch
        ↓
22 Nura/postmarketOS
        ↓
23 own Linux distribution
        ↓
24 mobile port
        ↓
25 RedmiLinux
```

---

# 52. Primer hito

No intentes completar todo de una vez.

El primer objetivo real es:

```text
Ubuntu/Debian
      |
      +-- Git
      +-- Clang/LLVM
      +-- ADB/Fastboot
      |
      v
Xiaomi kernel source
      |
      v
spes-r-oss
      |
      v
identificar defconfig
      |
      v
compilar
      |
      v
analizar resultado
```

Cuando esto funcione, comienza el verdadero trabajo de kernel.

---

# 53. Fuentes principales

## Xiaomi

https://github.com/MiCode/Xiaomi_Kernel_OpenSource

## Linux Kernel Documentation

https://docs.kernel.org/

## Rust for Linux

https://docs.kernel.org/rust/

## Android Open Source Project

https://source.android.com/

## Mobian

https://mobian-project.org/

## UBports / Ubuntu Touch

https://ubports.com/

## Nura

https://nura.eco/

## Operating Systems: Three Easy Pieces

https://pages.cs.wisc.edu/~remzi/OSTEP/

## Git

https://git-scm.com/doc

---

# 54. Nota específica sobre el Redmi Note 11

El árbol oficial de Xiaomi disponible para este dispositivo corresponde a `spes-r-oss` y Android R. En el ecosistema de desarrollo también existen árboles comunitarios más recientes para `spes/spesn`, pero deben considerarse fuentes de terceros y no sustituir automáticamente el árbol oficial.

Repositorio comunitario útil para estudiar:

https://github.com/spes-development/kernel_xiaomi_sm6225

No mezclar automáticamente:

```text
kernel Xiaomi oficial
+
device tree de otra ROM
+
vendor de otra versión
+
boot image de otra versión
```

Cada combinación debe ser compatible.

---

# 55. Principio final

El objetivo no es aprender una lista de comandos para "cambiar el kernel".

El objetivo es llegar a poder responder:

```text
¿Por qué funciona?
¿Por qué dejó de funcionar?
¿Qué componente lo controla?
¿Dónde está implementado?
¿Qué configuración lo activa?
¿Qué driver participa?
¿Qué hace el kernel?
¿Qué hace user space?
¿Cómo lo mido?
¿Cómo lo depuro?
¿Cómo lo revierto?
```

Cuando puedas responder esas preguntas, ya no estarás simplemente modificando un kernel: estarás haciendo ingeniería de sistemas.

---

# 56. Próximo laboratorio

Después de preparar este documento, el primer laboratorio concreto será:

1. identificar exactamente `spes`/`spesn`;
2. registrar Android y kernel actuales;
3. instalar el toolchain;
4. clonar `spes-r-oss`;
5. identificar `defconfig`;
6. estudiar el script de compilación;
7. crear un build directory;
8. realizar la primera compilación;
9. guardar logs;
10. comparar el kernel original con el artefacto generado.

**No flashear todavía.**

La primera meta es conseguir una compilación reproducible y entender exactamente qué produjo el compilador.
"""

out = "/mnt/data/guia_completa_redmi_note_11_kernel_os.md"
# pypandoc is required for markdown generation by the file-generation instructions.
pypandoc.convert_text(md, 'md', format='md', outputfile=out, extra_args=['--standalone'])
print(out)
