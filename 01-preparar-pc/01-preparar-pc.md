# Módulo 1 — Preparar el PC

- Estado: En progreso
- Fecha: 2026-10-05
- Host: Ubuntu 24.04.5 LTS (Noble), kernel 7.0.0-34-generic, x86_64
- Objetivo: tener un host Ubuntu con todas las herramientas para compilar un kernel ARM64 de forma cruzada, y conocer sus límites (RAM, disco, versión de Clang) antes de tocar el kernel del Redmi Note 11.

## Concepto

El teléfono es **ARM64** y este PC es **x86_64**, así que el kernel se compila de forma cruzada: el compilador corre en x86_64 y genera código para ARM64. Antes de bajar el código fuente hay que comprobar que están el compilador (`clang`), el linker (`ld.lld`), las utilidades LLVM, un GCC cruzado de respaldo para ARM64 y uno de 32 bits para el vDSO que Android exige, además de `dtc` para los Device Tree.

**Regla del módulo:** primero se comprueba qué hay (solo lectura), después se instala solo lo que falta.

## Práctica guiada

```bash
# Paso 1: diagnóstico del entorno (solo lectura)
cat /etc/os-release
uname -m
lscpu | grep -E "Model name|^CPU\(s\)"
free -h
df -h "$HOME"
git --version
make --version | head -1
gcc --version | head -1
clang --version | head -1
ld.lld --version
adb version
fastboot --version

# Paso 2: instalar lo que faltaba (modifica el sistema)
sudo apt update
sudo apt install -y lld llvm bc bison flex libssl-dev libelf-dev libncurses-dev \
  dwarves cpio rsync ccache device-tree-compiler \
  gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi

# Verificación
ld.lld --version
llvm-ar --version | head -2
aarch64-linux-gnu-gcc --version | head -1
arm-linux-gnueabi-gcc --version | head -1
dtc --version
```

## Hallazgos reales

1. **Faltaba una sola herramienta: `ld.lld`.** Git 2.43, Make 4.3, GCC 13.3, Clang 18.1.3, ADB y Fastboot 34.0.4 ya estaban instalados. `ld.lld` daba `command not found`; después de instalar el paquete `lld` responde `Ubuntu LLD 18.1.3`.
2. **Clang 18 es probablemente demasiado nuevo para el kernel 4.19 de Android.** Se anota ahora como riesgo y se confirmará en el Módulo 5: si la compilación falla por culpa del compilador, hará falta un Clang de la era Android 11 en `tools/` (no se instala con `apt`).
3. **La RAM manda el paralelismo.** El PC tiene 12 hilos pero solo 14 GiB de RAM (≈7,7 GiB disponibles con el sistema en uso). Para compilar se usará `make -j8` en lugar de `-j12` para no agotar la memoria.
4. **El disco es el recurso más justo:** 87 GB libres (81 % usado). El kernel, la ROM de fábrica y las compilaciones ocupan unos 30 GB; hay que vigilarlo.
5. **`lscpu | grep "Model name"` no devolvió el modelo** porque el sistema está en español y la etiqueta es "Nombre del modelo". Es un detalle de idioma, no un fallo.
6. **`apt` ofreció eliminar paquetes antiguos** (`linux-image-7.0.0-31-generic` y relacionados, "ya no son necesarios"). No se tocaron: no son parte de este módulo, pero liberarían espacio de disco si hiciera falta más adelante (`sudo apt autoremove`, revisando antes la lista).
7. **La instalación fue limpia:** `bc`, `libssl-dev`, `libncurses-dev`, `cpio` y `rsync` ya estaban en su versión más reciente; el resto se instaló sin errores.

## Versiones registradas

| Herramienta | Versión |
|---|---|
| Ubuntu | 24.04.5 LTS |
| Git | 2.43.0 |
| GNU Make | 4.3 |
| GCC | 13.3.0 |
| Clang / LLD / LLVM | 18.1.3 |
| `aarch64-linux-gnu-gcc` | 13.3.0 |
| `arm-linux-gnueabi-gcc` | 13.3.0 |
| DTC | 1.7.0 |
| ADB / Fastboot | 34.0.4 |

## Evidencias

**01 — Sistema, CPU, RAM y disco (hallazgos #3 y #4)**
`/etc/os-release`, `uname -m` (x86_64), `lscpu` (12 hilos), `free -h` (14 GiB) y `df -h` (87 GB libres, 81 % usado).
![Ubuntu 24.04, x86_64, 12 hilos, 14 GiB de RAM y 87 GB libres](evidencias/01-so-cpu-ram-disco.png)

**02 — Herramientas de compilación y falta de `ld.lld` (hallazgos #1 y #2)**
Versiones de Git, Make, GCC y Clang 18.1.3; `ld.lld` responde `No se ha encontrado la orden`.
![Git, Make, GCC y Clang presentes; ld.lld ausente](evidencias/02-git-make-gcc-clang-sin-lld.png)

**03 — ADB y Fastboot**
`adb version` y `fastboot --version`: ambos en 34.0.4, instalados en `/usr/lib/android-sdk/platform-tools/`.
![ADB y Fastboot 34.0.4 instalados](evidencias/03-adb-fastboot.png)

**04 — Inicio de la instalación (hallazgo #6 y #7)**
`apt install` con los paquetes indicados, paquetes ya instalados y la lista de paquetes antiguos "ya no necesarios".
![Inicio del apt install de las dependencias](evidencias/04-apt-install-inicio.png)

**05 — Fin de la instalación**
Configuración de `ccache`, `dwarves`, `gcc-aarch64-linux-gnu` y `gcc-arm-linux-gnueabi` sin errores.
![Final del apt install sin errores](evidencias/05-apt-install-fin.png)

**06 — Verificación de las herramientas nuevas**
`ld.lld` 18.1.3, `llvm-ar` 18.1.3, GCC cruzado ARM64 y ARM32 13.3.0, y `dtc` 1.7.0.
![lld, llvm-ar, GCCs cruzados y dtc funcionando](evidencias/06-verificacion-lld-llvm-gcc-dtc.png)

## Pendientes

- [ ] Instalar `mkbootimg` / `unpack_bootimg` (paquete de la distro o scripts de AOSP; se verifica con `which mkbootimg unpack_bootimg`).
- [ ] Regla `udev` y grupo `plugdev` para que `adb devices` vea el teléfono.
- [ ] Guardar la salida de versiones en `logs/01-versiones.txt`.
- [ ] Instalar `qemu-system-arm`, `strace` y `gdb` (se necesitan en módulos posteriores, no ahora).
- [ ] Cerrar el módulo y pasar al Módulo 2 (identificar el teléfono).
