# mobil-kernel-lab

Curso autodidacta de kernel Linux/Android sobre un **Xiaomi Redmi Note 11 (`spes`, Snapdragon 680, ARM64)**, tutorado por IA (Claude). Todo se valida **en el teléfono**; el PC solo compila el kernel y QEMU solo se usa para Rust del kernel.

## Metodología

- Cada módulo vive en `NN-nombre/NN-nombre.md` con teoría, práctica, **hallazgos reales** y evidencias con pie de foto.
- Las capturas y fotos crudas caen en `img/` (ignorada por Git) y luego se curan y renombran en `NN-nombre/evidencias/`.
- `logs/` guarda salidas crudas (hashes, `dmesg`, logs de compilación).
- `backup/` y `downloads/` (ROM y `boot.img` originales de Xiaomi) **no** se suben a Git: solo sus hashes SHA-256.
- Un commit por módulo o hito, con `Co-Authored-By: Claude`. El `git push` lo hago yo.
- Prefiero la verdad al guion: si algo no sale como dice la teoría, se documenta como hallazgo.

Guía de módulos: [GUIA_PASO_A_PASO.md](GUIA_PASO_A_PASO.md) · Prompt del mentor: [agent/MENTOR.md](agent/MENTOR.md)

## Progreso

**Módulo actual: 14 / 14 (completado, con el táctil pendiente)**

- [x] 01. Preparar el PC ([módulo](../01-preparar-pc/01-preparar-pc.md))
- [x] 02. Identificar el teléfono ([módulo](../02-identificar-telefono/02-identificar-telefono.md))
- [x] 03. Copias de seguridad, desbloqueo y recuperación ([módulo](../03-copias-seguridad/03-copias-seguridad.md))
- [x] 04. Descargar el kernel `spes-r-oss` ([módulo](../04-descargar-kernel/04-descargar-kernel.md))
- [x] 05. Compilar el kernel sin modificarlo ([módulo](../05-compilar-kernel/05-compilar-kernel.md))
- [x] 06. Analizar el `boot.img` original ([módulo](../06-analizar-boot-img/06-analizar-boot-img.md))
- [x] 07. El primer arranque con tu kernel ([módulo](../07-primer-arranque/07-primer-arranque.md))
- [x] 08. Depuración: `dmesg`, `pstore` ([módulo](../08-depuracion/08-depuracion.md))
- [x] 09. Primer módulo del kernel en C ([módulo](../09-primer-modulo-c/09-primer-modulo-c.md))
- [x] 10. Medir CPU, térmica y GPU ([módulo](../10-medir-cpu-termica-gpu/10-medir-cpu-termica-gpu.md))
- [x] 11. Rust (kernel en QEMU, programas en el teléfono) ([módulo](../11-rust/11-rust.md))
- [x] 12. Cambios propios al kernel ([módulo](../12-cambios-propios-al-kernel/12-cambios-propios-al-kernel.md))
- [x] 13. KernelSU (opcional) ([módulo](../13-kernelsu/13-kernelsu.md))
- [x] 14. Más allá de Android: Linux móvil ([módulo](../14-linux-movil/14-linux-movil.md)) — el kernel principal arranca en el teléfono con raíz persistente, SSH, web y Phosh; táctil pendiente
