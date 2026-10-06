# Curso completo: Ingeniería de Sistemas Operativos, Linux Kernel y Linux móvil

> **Laboratorio principal:** Xiaomi Redmi Note 11\
> **Entorno de desarrollo:** Ubuntu/Debian\
> **Lenguajes:** C como lenguaje principal + Rust como segundo lenguaje\
> **Arquitectura objetivo:** ARM64\
> **Metodología:** 80 % práctica · 20 % teoría\
> **Nivel:** desde fundamentos hasta kernel, drivers, Android,
> distribución Linux móvil y proyecto final

------------------------------------------------------------------------

## 0. Bienvenido al laboratorio

Este curso está diseñado para aprender ingeniería de sistemas operativos
trabajando con software real.

La meta no es solamente "compilar un kernel". El objetivo es comprender
progresivamente todas las capas que forman un sistema operativo moderno:

``` text
┌──────────────────────────────────────────┐
│ Aplicaciones                             │
│ apps móviles · terminal · herramientas   │
├──────────────────────────────────────────┤
│ Entorno gráfico y sesión                 │
│ Wayland · compositor · Phosh/Lomiri/etc. │
├──────────────────────────────────────────┤
│ Servicios y bibliotecas                  │
│ libc · red · audio · telefonía · init    │
├──────────────────────────────────────────┤
│ Sistema raíz / distribución              │
│ /etc · /usr · /var · paquetes · servicios │
├──────────────────────────────────────────┤
│ Linux Kernel                              │
│ procesos · memoria · drivers · seguridad │
├──────────────────────────────────────────┤
│ Hardware del Redmi Note 11               │
│ ARM64 · GPU · pantalla · UFS · radio     │
│ sensores · audio · USB · energía         │
└──────────────────────────────────────────┘
```

La distinción fundamental del curso será:

-   **Kernel:** administra CPU, memoria, procesos y comunicación con el
    hardware.
-   **Sistema operativo/distribución:** combina kernel, bibliotecas,
    servicios, herramientas y aplicaciones.
-   **Port móvil:** adapta un sistema a un dispositivo concreto,
    incluyendo kernel, controladores y componentes de hardware.
-   **Kernel desde cero:** implica implementar las funciones
    fundamentales del kernel sin partir del kernel Linux.

No son objetivos equivalentes. El curso permite estudiar los cuatro
niveles, pero los abordaremos progresivamente.

------------------------------------------------------------------------

# 1. Objetivos finales

Al terminar deberías poder:

-   Explicar qué hace un sistema operativo.
-   Diferenciar kernel, espacio de usuario, bibliotecas y servicios.
-   Programar en C con soltura suficiente para leer código de Linux.
-   Comprender punteros, memoria, estructuras, concurrencia y ABI.
-   Entender conceptos básicos de ensamblador ARM64.
-   Utilizar Git para desarrollo y revisión de cambios.
-   Leer el árbol de fuentes de Linux.
-   Entender Kconfig y Kbuild.
-   Configurar y compilar un kernel ARM64.
-   Comprender procesos, memoria virtual, planificación e
    interrupciones.
-   Crear y depurar código que se ejecute en el kernel cuando la
    plataforma lo permita.
-   Entender Device Tree y el modelo de drivers.
-   Analizar CPU, GPU, almacenamiento, energía y temperatura.
-   Entender el proceso de arranque de Android.
-   Analizar `boot.img`, `vendor_boot`, DTB/DTBO y ramdisk cuando
    correspondan.
-   Comprender Rust en Linux y sus límites de integración.
-   Construir un root filesystem mínimo.
-   Entender PID 1, `init`, servicios y logs.
-   Crear y empaquetar programas para una distribución Linux.
-   Comprender Wayland y los entornos gráficos móviles.
-   Estudiar red, Bluetooth, USB, audio, sensores y telefonía.
-   Comprender SELinux, permisos, capabilities, namespaces y cgroups.
-   Construir una distribución experimental para QEMU.
-   Investigar la adaptación de Linux móvil al Redmi Note 11.
-   Mantener todo el trabajo reproducible y documentado.

------------------------------------------------------------------------

# 2. Regla principal: primero el laboratorio, después el teléfono

**No empezaremos flasheando nada.**

El Redmi será el laboratorio de integración, pero los experimentos
peligrosos o difíciles se realizarán primero en:

1.  Ubuntu/Debian.
2.  QEMU.
3.  Una máquina virtual cuando sea conveniente.
4.  Un entorno de recuperación.
5.  Finalmente el teléfono real.

Un kernel que compila no significa que sea arrancable en el teléfono.

Un sistema Linux que arranca tampoco significa que funcionen:

-   pantalla,
-   GPU,
-   cámara,
-   audio,
-   sensores,
-   Wi-Fi,
-   Bluetooth,
-   módem,
-   suspensión,
-   aceleración gráfica,
-   gestión energética.

------------------------------------------------------------------------

# 3. Identificación obligatoria del Redmi Note 11

## 3.1 No asumir el modelo

"Redmi Note 11" puede referirse a variantes diferentes según mercado,
región y plataforma.

Antes de elegir:

-   repositorio,
-   rama,
-   `defconfig`,
-   Device Tree,
-   toolchain,
-   imagen de arranque,
-   firmware,

hay que identificar el dispositivo real.

Si Android funciona y ADB está disponible:

``` bash
adb devices

adb shell getprop ro.product.model
adb shell getprop ro.product.device
adb shell getprop ro.product.name
adb shell getprop ro.board.platform
adb shell getprop ro.build.version.release
adb shell getprop ro.build.version.sdk
adb shell uname -a
```

También podemos recopilar:

``` bash
adb shell cat /proc/cpuinfo
adb shell cat /proc/version
adb shell getprop | grep -E 'ro.product|ro.board|ro.build.version'
```

**No publiques números de serie o identificadores personales del
dispositivo.**

## 3.2 Ficha técnica del laboratorio

Completar antes del módulo específico del teléfono:

``` text
Modelo:
Codename:
SoC:
CPU:
GPU:
RAM:
Almacenamiento:
Android:
API:
Kernel:
Bootloader:
ROM:
Región:
Estado de bootloader:
```

Hasta completar esta ficha, los comandos de compilación específicos del
Redmi quedan deliberadamente pendientes.

------------------------------------------------------------------------

# 4. Filosofía de trabajo

Cada concepto debe terminar en algo verificable.

La estructura de cada laboratorio será:

### 1. Teoría

5--20 minutos.

### 2. Lectura

Buscar la implementación real en código.

### 3. Escritura

Crear o modificar código.

### 4. Compilación

Ejecutar las herramientas y entender los errores.

### 5. Prueba

Verificar el resultado.

### 6. Depuración

Analizar logs, errores y comportamiento.

### 7. Git

Registrar el cambio.

### 8. Bitácora

Documentar:

``` text
Qué intenté
Qué esperaba
Qué ocurrió
Qué error apareció
Por qué ocurrió
Cómo lo solucioné
Qué aprendí
Cómo reproducirlo
Cómo revertirlo
```

------------------------------------------------------------------------

# 5. Estructura completa del curso

## Fase I --- Fundamentos

-   Módulo 1 --- Entorno y compilación cruzada
-   Módulo 2 --- Fundamentos de sistemas operativos
-   Módulo 3 --- C, ARM64 y herramientas de bajo nivel

## Fase II --- Kernel

-   Módulo 4 --- Anatomía interna de Linux
-   Módulo 5 --- Procesos, memoria y concurrencia
-   Módulo 6 --- Módulos y programación del kernel en C
-   Módulo 7 --- Rust dentro de Linux

## Fase III --- Android y hardware

-   Módulo 8 --- Android, bootloader y arranque
-   Módulo 9 --- Drivers, hardware y rendimiento
-   Módulo 10 --- Depuración, pruebas y calidad

## Fase IV --- Sistema operativo completo

-   Módulo 11 --- Proyecto de kernel personalizado
-   Módulo 12 --- Root filesystem
-   Módulo 13 --- Inicio y servicios
-   Módulo 14 --- Paquetes y construcción de distribuciones
-   Módulo 15 --- Interfaz gráfica móvil
-   Módulo 16 --- Red, telefonía y periféricos
-   Módulo 17 --- Seguridad y aislamiento
-   Módulo 18 --- Construcción de una distribución propia

## Fase V --- Proyecto móvil

-   Módulo 19 --- Portabilidad Linux móvil al Redmi Note 11
-   Módulo 20 --- Integración completa y sistema experimental propio

------------------------------------------------------------------------

# 6. Módulo 1 --- Entorno de desarrollo y compilación cruzada

## Objetivo

Construir un entorno reproducible para desarrollar Linux y preparar la
compilación ARM64.

### Temas

-   Ubuntu/Debian.
-   Git.
-   Make.
-   GCC.
-   Clang.
-   LLVM.
-   LLD.
-   Python.
-   Device Tree Compiler.
-   ADB.
-   Fastboot.
-   arquitectura anfitrión frente a arquitectura objetivo.
-   compilación cruzada.

### Instalación inicial

``` bash
sudo apt update

sudo apt install -y \
  git curl wget ca-certificates \
  build-essential bc bison flex \
  libssl-dev libelf-dev libncurses-dev \
  dwarves python3 python3-pip \
  unzip zip xz-utils \
  clang llvm lld \
  device-tree-compiler \
  adb fastboot
```

Los requisitos exactos pueden cambiar según la rama del kernel.

### Verificación

``` bash
git --version
gcc --version
clang --version
ld.lld --version
make --version
adb version
fastboot --version
```

Comprobar ARM64:

``` bash
clang --target=aarch64-linux-gnu -v
```

### Espacio de laboratorio

``` bash
mkdir -p ~/kernel-lab/{src,build,downloads,logs}
cd ~/kernel-lab

pwd
df -h "$HOME"
nproc
free -h
```

### Git

Configurar identidad:

``` bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu-correo@example.com"
```

No es necesario utilizar el correo real del dispositivo; usa una
identidad apropiada para tus repositorios.

### Entrega

Crear:

``` text
~/kernel-lab/logs/environment.txt
```

con las versiones y características del sistema.

------------------------------------------------------------------------

# 7. Módulo 2 --- Fundamentos de sistemas operativos

## Objetivo

Entender qué problema resuelve el kernel antes de modificarlo.

### 2.1 Kernel frente a espacio de usuario

Estudiar:

-   user space,
-   kernel space,
-   privilegios,
-   llamadas al sistema,
-   bibliotecas.

Laboratorio:

``` bash
strace ./programa
```

cuando `strace` esté disponible.

### 2.2 Procesos e hilos

Aprender:

-   PID.
-   procesos.
-   hilos.
-   contexto.
-   planificación.

Crear un programa C que utilice procesos e hilos.

### 2.3 Memoria

Estudiar:

-   memoria virtual,
-   memoria física,
-   páginas,
-   stack,
-   heap,
-   mmap.

Observar:

``` bash
cat /proc/meminfo
cat /proc/self/maps
```

### 2.4 Archivos y VFS

Estudiar:

-   file descriptors,
-   `open`,
-   `read`,
-   `write`,
-   `close`,
-   VFS.

### 2.5 Interrupciones

Comprender:

``` text
Hardware
   ↓
Interrupción
   ↓
Kernel
   ↓
Driver
   ↓
Subsistema
   ↓
Aplicación/servicio
```

### Proyecto

Crear una herramienta C que muestre información de:

-   procesos,
-   memoria,
-   descriptores,
-   llamadas al sistema.

------------------------------------------------------------------------

# 8. Módulo 3 --- C, ensamblador ARM64 y bajo nivel

## Objetivo

Dominar las herramientas necesarias para leer código de kernel.

### Temas

-   punteros,
-   estructuras,
-   arrays,
-   alineación,
-   padding,
-   memoria dinámica,
-   representación binaria,
-   endianess,
-   ABI,
-   registros ARM64,
-   llamadas a funciones,
-   ensamblador generado.

### Laboratorios

``` c
sizeof(...)
```

Analizar tamaños y alineación.

Después:

``` bash
objdump
readelf
nm
```

Inspeccionar binarios.

### Depuración

Estudiar:

-   GDB,
-   breakpoints,
-   stack traces,
-   errores de memoria,
-   sanitizadores.

### Proyecto

Construir un analizador de cabeceras binarias.

------------------------------------------------------------------------

# 9. Módulo 4 --- Anatomía interna del kernel Linux

## Objetivo

Aprender a navegar un árbol de kernel real.

### Directorios esenciales

``` text
arch/
block/
drivers/
fs/
include/
init/
ipc/
kernel/
lib/
mm/
net/
scripts/
security/
```

### Especial atención

``` text
arch/arm64/
kernel/
mm/
drivers/
include/
```

### Kconfig

Estudiar:

-   símbolos,
-   dependencias,
-   `bool`,
-   `tristate`,
-   configuración.

### Kbuild

Estudiar:

-   Makefiles,
-   objetos `.o`,
-   built-in,
-   módulos,
-   enlazado.

### Práctica

Elegir una opción:

``` text
CONFIG_...
```

y seguirla:

``` text
Kconfig
  ↓
.config
  ↓
código C
  ↓
Makefile/Kbuild
  ↓
.o
  ↓
kernel
```

### Proyecto

Documentar el recorrido completo de una opción de configuración.

------------------------------------------------------------------------

# 10. Módulo 5 --- Procesos, memoria y concurrencia

## Objetivo

Entender las estructuras fundamentales del kernel.

### Procesos

Estudiar:

``` text
task_struct
scheduler
context switch
```

### Memoria

Estudiar:

``` text
kmalloc
kfree
pages
virtual memory
```

### Concurrencia

Estudiar:

-   mutex,
-   spinlock,
-   atomic,
-   condiciones de carrera,
-   sincronización.

### Regla

Antes de escribir código concurrente en kernel hay que comprender las
invariantes que debe preservar.

### Proyecto

Herramienta de observación de carga y memoria.

------------------------------------------------------------------------

# 11. Módulo 6 --- Primer código dentro del kernel

## Objetivo

Pasar de leer el kernel a escribir código que se ejecute en él.

### Ciclo de vida

``` c
module_init()
module_exit()
```

### Conceptos

-   metadatos,
-   licencia,
-   módulos,
-   código integrado,
-   Kbuild.

### Logs

``` c
printk()
```

Analizar:

``` bash
dmesg
```

y cuando esté disponible:

``` bash
cat /dev/kmsg
```

### Interfaces

Estudiar:

``` text
/proc
/sys
```

### Importante

Android puede no permitir módulos externos de la misma forma que una
distribución Linux convencional.

Si el kernel objetivo no permite el ejercicio:

1.  practicar en Linux/QEMU;
2.  usar un kernel de laboratorio;
3.  integrar el ejercicio en el árbol de fuentes cuando sea apropiado.

No es necesario desactivar protecciones del teléfono.

------------------------------------------------------------------------

# 12. Módulo 7 --- Rust dentro de Linux

## Objetivo

Entender qué aporta Rust y cuáles son sus límites dentro del kernel.

### Rust convencional

Aprender:

-   ownership,
-   borrowing,
-   lifetimes,
-   enums,
-   traits,
-   errores,
-   concurrencia.

### Kernel

Estudiar:

-   `no_std`,
-   restricciones del kernel,
-   FFI,
-   ABI,
-   interacción C/Rust,
-   Kconfig,
-   Kbuild.

### Proyecto

Crear una pequeña contribución en Rust compatible con la versión de
kernel seleccionada, solo cuando la configuración y el toolchain lo
permitan.

**No asumir que una rama antigua de Android soporta el mismo Rust que un
kernel Linux moderno.**

------------------------------------------------------------------------

# 13. Módulo 8 --- Android, bootloader y arranque

## Objetivo

Comprender cómo el kernel forma parte de Android.

### Cadena conceptual

``` text
Boot ROM
   ↓
Bootloader
   ↓
Boot image / componentes de arranque
   ↓
Kernel
   ↓
init
   ↓
Servicios
   ↓
Android userspace
```

### Estudiar

-   ADB.
-   Fastboot.
-   bootloader.
-   recovery.
-   ramdisk.
-   `boot.img`.
-   `vendor_boot`.
-   DTB.
-   DTBO.
-   verificación.
-   particiones.

### ADB

``` bash
adb shell
adb shell uname -a
adb shell getprop
```

### Fastboot

Primero aprender a identificar el dispositivo:

``` bash
adb reboot bootloader
fastboot devices
```

**No ejecutar comandos de escritura o borrado hasta haber estudiado el
procedimiento de recuperación específico del dispositivo.**

### Proyecto

Analizar una imagen original y documentar sus componentes.

------------------------------------------------------------------------

# 14. Módulo 9 --- Drivers, hardware y rendimiento

## Objetivo

Comprender cómo Linux controla el hardware.

### CPU

Estudiar:

-   cpufreq,
-   governors,
-   afinidad,
-   scheduler,
-   frecuencia,
-   carga.

### GPU

Estudiar:

-   arquitectura del driver,
-   firmware,
-   userspace,
-   frecuencia,
-   temperatura.

### Device Tree

Estudiar:

``` text
SoC
 ↓
Device Tree
 ↓
Driver
 ↓
Hardware
```

Conceptos:

-   nodos,
-   propiedades,
-   phandles,
-   recursos,
-   IRQ,
-   clocks,
-   regulators.

### Energía

Estudiar:

-   thermal zones,
-   sensores,
-   suspensión,
-   consumo,
-   frecuencia dinámica.

### Regla

**Medir antes de optimizar.**

Nunca comenzar modificando voltajes o desactivando protecciones
térmicas.

### Proyecto

Comparación A/B:

``` text
Kernel original
      vs
Kernel modificado
```

medir:

-   rendimiento,
-   temperatura,
-   estabilidad,
-   consumo estimado.

------------------------------------------------------------------------

# 15. Módulo 10 --- Depuración y calidad

## Objetivo

Aprender a demostrar que un cambio funciona.

### Herramientas

-   `dmesg`
-   logs
-   tracing
-   símbolos
-   GDB
-   Git
-   tests
-   stress tests

### Diferenciar

``` text
Kernel panic
   ≠
Bloqueo de userspace
   ≠
Error de driver
   ≠
Problema de firmware
   ≠
Problema de hardware
```

### Proyecto

Reproducir un error controlado en laboratorio, recopilar evidencias y
demostrar que la corrección no rompe pruebas anteriores.

------------------------------------------------------------------------

# 16. Módulo 11 --- Proyecto de kernel personalizado

## Objetivo

Crear una modificación pequeña, reproducible y verificable.

### Orden recomendado

1.  Cambiar una opción de configuración.
2.  Añadir mensajes de diagnóstico.
3.  Crear una interfaz de solo lectura.
4.  Modificar una función no crítica.
5.  Medir un subsistema de rendimiento.
6.  Integrar el cambio en una imagen adecuada.

### Entregables

``` text
README.md
config/
patches/
scripts/
logs/
tests/
```

Debe contener:

-   versión de herramientas,
-   commit,
-   configuración,
-   parches,
-   comandos,
-   pruebas,
-   resultados,
-   procedimiento de recuperación.

------------------------------------------------------------------------

# 17. Módulo 12 --- Construcción del sistema raíz

## Objetivo

Dejar de pensar solamente en el kernel y construir el entorno que lo
rodea.

### Jerarquía

``` text
/
├── bin/
├── dev/
├── etc/
├── home/
├── lib/
├── proc/
├── root/
├── run/
├── sys/
├── tmp/
├── usr/
└── var/
```

### Estudiar

-   ELF.
-   bibliotecas compartidas.
-   linker.
-   `libc`.
-   `/proc`.
-   `/sys`.
-   `/dev`.
-   `initramfs`.
-   `chroot`.

### Proyecto

Construir un root filesystem mínimo.

Objetivo:

``` text
Linux Kernel
     ↓
initramfs
     ↓
/init
     ↓
shell
```

Preferentemente en QEMU.

------------------------------------------------------------------------

# 18. Módulo 13 --- Inicio y servicios

## Objetivo

Entender PID 1.

### Estudiar

-   `init`.
-   PID 1.
-   servicios.
-   señales.
-   logs.
-   apagado.
-   dependencias.

En una distribución Linux:

``` text
kernel
  ↓
PID 1
  ↓
servicios
  ↓
sesión
```

Estudiar `systemd` como referencia, pero también comprender el concepto
general de init.

### Proyecto

Crear un servicio propio en el sistema de laboratorio.

------------------------------------------------------------------------

# 19. Módulo 14 --- Paquetes y construcción de distribuciones

## Objetivo

Comprender cómo se convierte software fuente en un sistema instalable.

### Estudiar

-   repositorios,
-   dependencias,
-   paquetes binarios,
-   compilación,
-   recetas,
-   imágenes,
-   actualización.

Comparar:

``` text
Debian
Alpine
```

### Proyecto

Crear un paquete para el laboratorio.

------------------------------------------------------------------------

# 20. Módulo 15 --- Interfaz gráfica móvil

## Objetivo

Comprender la capa gráfica de un sistema Linux móvil.

### Arquitectura

``` text
Aplicación
   ↓
Toolkit GTK / Qt
   ↓
Compositor
   ↓
Wayland
   ↓
Driver gráfico
   ↓
GPU
```

### Estudiar

-   Wayland.
-   compositor.
-   sesión gráfica.
-   pantalla de bloqueo.
-   touch.
-   escalado.
-   GTK.
-   Qt.
-   Phosh.
-   Lomiri.
-   Plasma Mobile.

### Proyecto

Ejecutar una interfaz móvil en QEMU o hardware compatible y crear una
aplicación sencilla.

------------------------------------------------------------------------

# 21. Módulo 16 --- Red, telefonía y periféricos

## Objetivo

Comprender las capas necesarias para convertir Linux en un sistema
móvil.

### Estudiar

-   Ethernet conceptual.
-   Wi-Fi.
-   Bluetooth.
-   USB.
-   audio.
-   sensores.
-   cámara.
-   almacenamiento.
-   modem.
-   telefonía.

### Software de userspace

Investigar según la plataforma:

-   NetworkManager.
-   ModemManager.
-   PipeWire/Audio.
-   servicios de sesión.

### Arquitectura

``` text
Aplicación
 ↓
Servicio
 ↓
HAL / interfaz
 ↓
Driver
 ↓
Firmware
 ↓
Hardware
```

### Proyecto

Documentar qué componentes funcionan y cuáles faltan en el dispositivo
objetivo.

------------------------------------------------------------------------

# 22. Módulo 17 --- Seguridad y aislamiento

## Objetivo

Comprender la seguridad del sistema completo.

### Estudiar

-   usuarios.
-   grupos.
-   permisos.
-   capabilities.
-   namespaces.
-   cgroups.
-   SELinux.
-   AppArmor.
-   cadena de confianza.
-   actualizaciones.

### Android

Investigar:

-   SELinux.
-   sandboxing.
-   permisos.
-   verified boot.
-   separación de componentes.

### Proyecto

Ejecutar una aplicación con privilegios mínimos y documentar su
aislamiento.

------------------------------------------------------------------------

# 23. Módulo 18 --- Construir una distribución propia

## Objetivo

Construir un sistema Linux experimental completo.

### Componentes

``` text
Kernel
+
Root filesystem
+
Init
+
Servicios
+
Paquetes
+
Sesión gráfica
+
Aplicaciones
```

### Proyecto

Construir una distribución mínima para QEMU.

Debe poder:

1.  arrancar;
2.  ejecutar `/init`;
3.  montar `/proc`;
4.  montar `/sys`;
5.  iniciar una shell;
6.  ejecutar programas;
7.  registrar eventos;
8.  apagarse correctamente.

------------------------------------------------------------------------

# 24. Módulo 19 --- Portabilidad Linux móvil al Redmi Note 11

Este módulo será específico del hardware identificado en el laboratorio.

**No se utilizará una rama o configuración hasta conocer el
modelo/codename exacto.**

## 19.1 Investigación

Identificar:

-   codename;
-   SoC;
-   kernel;
-   Android;
-   boot image;
-   Device Tree;
-   firmware;
-   particiones;
-   drivers;
-   componentes propietarios.

## 19.2 Comparación

Construir una tabla:

  Componente   Android original   Linux móvil   Estado
  ------------ ------------------ ------------- --------
  Kernel                                        
  Pantalla                                      
  Touch                                         
  GPU                                           
  Wi-Fi                                         
  Bluetooth                                     
  Audio                                         
  Cámara                                        
  Sensores                                      
  Modem                                         
  USB                                           
  UFS                                           
  Energía                                       

## 19.3 Casos de estudio

Estudiar:

-   Ubuntu Touch.
-   Halium.
-   Mobian.
-   postmarketOS/Nura.
-   kernels Android.
-   mainline Linux.

La idea no es copiar proyectos completos, sino comprender cómo
solucionan:

``` text
Hardware Android
       ↓
Kernel
       ↓
Compatibilidad
       ↓
Linux userspace
       ↓
Interfaz móvil
```

### Advertencia

Que un teléfono pueda ejecutar Linux no significa que todos sus
componentes tengan soporte completo.

------------------------------------------------------------------------

# 25. Módulo 20 --- Sistema móvil experimental propio

## Objetivo final

Construir una demostración reproducible de un sistema Linux móvil
personalizado.

### Arquitectura objetivo

``` text
┌──────────────────────────────┐
│ Aplicaciones                 │
├──────────────────────────────┤
│ Interfaz móvil               │
├──────────────────────────────┤
│ Servicios                    │
├──────────────────────────────┤
│ Root filesystem              │
├──────────────────────────────┤
│ Kernel Linux modificado      │
├──────────────────────────────┤
│ Drivers / firmware           │
├──────────────────────────────┤
│ Hardware Redmi Note 11       │
└──────────────────────────────┘
```

### Proyecto final

El proyecto debe producir:

``` text
kernel personalizado
+
configuración
+
scripts
+
rootfs o imagen de laboratorio
+
programas/servicios propios
+
pruebas
+
documentación
```

No es obligatorio reemplazar completamente Android para completar el
curso.

La meta es demostrar comprensión y control progresivo de las capas.

------------------------------------------------------------------------

# 26. Git: obligatorio desde el día 1

Nunca trabajar con cambios sin registrar.

Estructura recomendada:

``` text
kernel-lab/
├── src/
├── build/
├── downloads/
├── logs/
├── patches/
├── scripts/
├── tests/
└── docs/
```

Antes de modificar:

``` bash
git status
git diff
```

Después:

``` bash
git diff
git status
git add .
git commit -m "Descripción del cambio"
```

Crear ramas:

``` bash
git switch -c laboratorio/nombre-del-experimento
```

Regla:

> Si un cambio no puede explicarse, compararse y revertirse, todavía no
> está listo para el laboratorio.

------------------------------------------------------------------------

# 27. Bitácora del curso

Crear:

``` text
docs/bitacora.md
```

Plantilla:

``` markdown
# Laboratorio XX

## Objetivo

## Hardware

## Software

## Commit

## Configuración

## Comandos

## Resultado esperado

## Resultado obtenido

## Error

## Diagnóstico

## Solución

## Pruebas

## Conclusión

## Cómo revertir
```

------------------------------------------------------------------------

# 28. Política de recuperación

Antes de probar una modificación en hardware real:

-   conocer el modelo exacto;
-   conocer el codename;
-   conocer la ROM instalada;
-   conocer el estado del bootloader;
-   conservar una versión funcional;
-   entender el método de recuperación;
-   verificar qué partición se modificaría;
-   tener batería suficiente;
-   tener acceso a otro ordenador si es necesario.

**Nunca borrar una partición simplemente porque un tutorial lo indica.**

**Nunca flashear una imagen de otro modelo.**

**Nunca asumir que dos teléfonos con el mismo nombre comercial utilizan
el mismo kernel.**

------------------------------------------------------------------------

# 29. Medición antes de optimización

Para cualquier cambio de rendimiento registrar primero:

``` text
Temperatura
Frecuencia CPU
Carga CPU
RAM
I/O
FPS cuando corresponda
Latencia
Estabilidad
Consumo estimado
Duración de la prueba
```

Comparación:

``` text
BASELINE
   ↓
CAMBIO
   ↓
MISMA PRUEBA
   ↓
COMPARACIÓN
   ↓
CONCLUSIÓN
```

No optimizar basándose únicamente en benchmarks.

------------------------------------------------------------------------

# 30. Orden recomendado de modificaciones

### Nivel 1 --- Configuración

Cambiar una opción de `CONFIG_`.

### Nivel 2 --- Diagnóstico

Añadir logs.

### Nivel 3 --- Observación

Crear una interfaz de solo lectura.

### Nivel 4 --- Código

Modificar una función no crítica.

### Nivel 5 --- Subsistema

Investigar un driver o subsistema.

### Nivel 6 --- Rendimiento

Modificar y medir.

### Nivel 7 --- Integración

Construir la imagen correspondiente.

### Nivel 8 --- Hardware

Probar siguiendo el procedimiento de recuperación.

------------------------------------------------------------------------

# 31. Ruta de estudio de 24+ semanas

  Semanas   Contenido
  --------- ------------------------------------
  1--2      Entorno, Git y compilación cruzada
  3--4      Fundamentos de sistemas operativos
  5--6      C y ARM64
  7--8      Anatomía del kernel
  9--10     Procesos, memoria y concurrencia
  11--12    Módulos y programación kernel
  13--14    Rust
  15--16    Android y boot
  17--19    Drivers, hardware y rendimiento
  20        Depuración y calidad
  21--22    Root filesystem e init
  23--24    Servicios y paquetes
  25--26    Interfaz gráfica móvil
  27--28    Red, telefonía y periféricos
  29--30    Seguridad
  31--32    Distribución Linux propia
  33--36    Portabilidad al Redmi Note 11
  37+       Proyecto móvil experimental

El calendario es orientativo. Si un concepto fundamental no está
entendido, se amplía el módulo.

------------------------------------------------------------------------

# 32. Distribución semanal

Para 6--10 horas:

``` text
1 h     teoría
2 h     lectura de código
3–5 h   programación/compilación
1 h     pruebas y documentación
```

Una semana no se considera terminada simplemente porque los comandos
funcionen.

Debe poder explicarse:

-   qué ocurrió;
-   por qué ocurrió;
-   qué archivo lo produjo;
-   qué herramienta participó;
-   cómo reproducirlo;
-   cómo revertirlo.

------------------------------------------------------------------------

# 33. Proyecto paralelo: Linux en QEMU

Antes de experimentar agresivamente con el Redmi:

``` text
Kernel Linux
    +
Root filesystem
    +
QEMU
```

Objetivos:

-   arrancar un kernel;
-   entrar en shell;
-   montar `/proc`;
-   montar `/sys`;
-   ejecutar programas;
-   producir logs;
-   provocar errores controlados;
-   depurar.

QEMU será nuestro "teléfono virtual" para muchos experimentos
conceptuales.

------------------------------------------------------------------------

# 34. Proyectos de referencia

## Ubuntu Touch

Estudiar:

-   portabilidad móvil;
-   Lomiri;
-   integración Android;
-   Halium;
-   servicios.

## Mobian

Estudiar:

-   Debian móvil;
-   paquetes;
-   servicios;
-   soporte de hardware.

## postmarketOS / Nura

Estudiar:

-   Alpine;
-   paquetes;
-   kernels;
-   dispositivos;
-   mainline;
-   portabilidad.

Estos proyectos son **casos de estudio**, no una garantía de
compatibilidad con el Redmi Note 11.

------------------------------------------------------------------------

# 35. Qué significa "crear mi propio sistema operativo"

Existen diferentes niveles:

  Nivel                      Qué construyes
  -------------------------- ------------------------------------------
  Personalizar Android       Kernel, configuración, servicios o ROM
  Crear distribución Linux   Kernel + rootfs + paquetes + servicios
  Crear sistema móvil        Distribución + interfaz + hardware móvil
  Crear kernel               Scheduler + memoria + drivers + syscalls
  Kernel desde cero          Implementar el núcleo sin Linux

El curso comienza en el primer nivel y avanza hacia los siguientes.

------------------------------------------------------------------------

# 36. Checklist inicial

Antes de comenzar el primer laboratorio:

-   [ ] Ubuntu/Debian instalado.
-   [ ] Git instalado.
-   [ ] Clang instalado.
-   [ ] LLVM instalado.
-   [ ] Make instalado.
-   [ ] ADB instalado.
-   [ ] Fastboot instalado.
-   [ ] QEMU instalado.
-   [ ] Git configurado.
-   [ ] `~/kernel-lab` creado.
-   [ ] Redmi conectado por ADB si es posible.
-   [ ] Modelo identificado.
-   [ ] Codename identificado.
-   [ ] SoC identificado.
-   [ ] Android identificado.
-   [ ] Kernel identificado.
-   [ ] ROM identificada.
-   [ ] Estado del bootloader identificado.
-   [ ] Bitácora creada.

------------------------------------------------------------------------

# 37. Primer laboratorio

**No descargar todavía una rama arbitraria del kernel del Redmi.**

Primero ejecuta:

``` bash
adb devices

adb shell getprop ro.product.model
adb shell getprop ro.product.device
adb shell getprop ro.product.name
adb shell getprop ro.board.platform
adb shell getprop ro.build.version.release
adb shell getprop ro.build.version.sdk
adb shell uname -a
```

Guarda el resultado en:

``` text
~/kernel-lab/logs/device-info.txt
```

Después:

``` bash
mkdir -p ~/kernel-lab/{src,build,downloads,logs,patches,scripts,tests,docs}
```

Y verifica:

``` bash
uname -m
clang --version
llvm-config --version
git --version
make --version
adb version
fastboot --version
```

------------------------------------------------------------------------

# 38. Entrega del Módulo 1

Al terminar tendrás que entregar:

``` text
device-info.txt
environment.txt
```

y una ficha:

``` markdown
# Mi laboratorio

## Ordenador

CPU:
RAM:
Distribución:
Versión:
Arquitectura:

## Redmi

Modelo:
Codename:
SoC:
Android:
Kernel:
ROM:

## Herramientas

GCC:
Clang:
LLVM:
LLD:
Git:
Make:
ADB:
Fastboot:

## Observaciones
```

Con esta información se seleccionará posteriormente el árbol de kernel y
el procedimiento correspondiente.

------------------------------------------------------------------------

# 39. Regla de oro del curso

> **No copies comandos: entiende qué hacen.**

Si aparece:

``` bash
make
```

debes preguntar:

-   ¿qué Makefile?
-   ¿qué arquitectura?
-   ¿qué configuración?
-   ¿qué toolchain?
-   ¿qué objetos se generan?
-   ¿qué imagen produce?
-   ¿dónde termina el resultado?

Si aparece:

``` c
kmalloc(...)
```

debes preguntar:

-   ¿en qué contexto?
-   ¿qué flags?
-   ¿qué tamaño?
-   ¿qué pasa si falla?
-   ¿quién libera la memoria?
-   ¿puede ejecutarse concurrentemente?

Si aparece:

``` text
boot.img
```

debes preguntar:

-   ¿qué versión de header?
-   ¿qué kernel contiene?
-   ¿hay ramdisk?
-   ¿dónde está el DTB?
-   ¿qué requiere la ROM?
-   ¿cómo se verifica?
-   ¿cómo se recupera el dispositivo si falla?

------------------------------------------------------------------------

# 40. Resultado final esperado

Al finalizar no tendrás solamente "un kernel modificado".

Tendrás un repositorio organizado capaz de explicar:

``` text
Aplicación
    ↓
Bibliotecas
    ↓
Servicios
    ↓
Sistema raíz
    ↓
Kernel
    ↓
Drivers
    ↓
Firmware
    ↓
Hardware
```

Y podrás seguir el recorrido contrario:

``` text
Hardware
    ↓
Driver
    ↓
Kernel
    ↓
Servicio
    ↓
Biblioteca
    ↓
Aplicación
```

Ese es el objetivo real del curso:

**aprender ingeniería de sistemas operativos trabajando sobre un sistema
Linux/Android real y, progresivamente, ser capaz de construir y
modificar las capas que lo forman.**

------------------------------------------------------------------------

# 41. Estado del curso

``` text
[ ] Módulo 1 — Entorno
[ ] Módulo 2 — Sistemas operativos
[ ] Módulo 3 — C y ARM64
[ ] Módulo 4 — Kernel internals
[ ] Módulo 5 — Procesos/memoria/concurrencia
[ ] Módulo 6 — Kernel C
[ ] Módulo 7 — Rust
[ ] Módulo 8 — Android/boot
[ ] Módulo 9 — Drivers/hardware
[ ] Módulo 10 — Debugging
[ ] Módulo 11 — Kernel personalizado
[ ] Módulo 12 — Root filesystem
[ ] Módulo 13 — Init/servicios
[ ] Módulo 14 — Paquetes
[ ] Módulo 15 — GUI móvil
[ ] Módulo 16 — Red/telefonía/periféricos
[ ] Módulo 17 — Seguridad
[ ] Módulo 18 — Distribución propia
[ ] Módulo 19 — Port Redmi Note 11
[ ] Módulo 20 — Sistema móvil experimental
```

------------------------------------------------------------------------

## Próximo paso

**No compiles todavía el kernel del teléfono.**

Primero completa el **Módulo 1** y obtén la identificación exacta del
Redmi Note 11:

``` bash
adb shell getprop ro.product.model
adb shell getprop ro.product.device
adb shell getprop ro.board.platform
adb shell getprop ro.build.version.release
adb shell uname -a
```

Con esos datos podremos determinar qué árbol de kernel, configuración,
toolchain y procedimiento corresponden realmente a tu dispositivo.
