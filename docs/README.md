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

**Módulo actual: 3 / 14**

- [x] 01. Preparar el PC ([módulo](../01-preparar-pc/01-preparar-pc.md))
- [x] 02. Identificar el teléfono ([módulo](../02-identificar-telefono/02-identificar-telefono.md))
- [ ] 03. Copias de seguridad, desbloqueo y recuperación
- [ ] 04. Descargar el kernel `spes-r-oss`
- [ ] 05. Compilar el kernel sin modificarlo
- [ ] 06. Analizar el `boot.img` original
- [ ] 07. `boot-lab.img` y primer arranque
- [ ] 08. Depuración: `dmesg`, `pstore`
- [ ] 09. Primer módulo del kernel en C
- [ ] 10. Medir CPU, térmica y GPU
- [ ] 11. Rust (kernel en QEMU, programas en el teléfono)
- [ ] 12. Cambios propios al kernel
- [ ] 13. KernelSU (opcional)
- [ ] 14. Linux móvil y sistema propio
