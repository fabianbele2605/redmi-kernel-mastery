# Módulo 4 — Descargar el kernel `spes-r-oss`

- Estado: En progreso
- Fecha: 2026-10-06
- Fuente: <https://github.com/MiCode/Xiaomi_Kernel_OpenSource>, rama `spes-r-oss`
- Objetivo: tener el código fuente oficial de Xiaomi para `spes`, saber exactamente qué commit y qué versión de kernel es, y localizar su `defconfig` y las instrucciones de compilación. No se compila todavía (Módulo 5) y no hace falta el teléfono.

## Concepto

Un kernel no se compila "a ciegas": hay que saber qué árbol de código es, en qué commit está y qué configuración (`defconfig`) lo describe. Un commit identifica el contenido exacto; registrarlo hace el laboratorio **reproducible**. Se clona solo el último commit (`--depth=1`) de una sola rama para no descargar cientos de miles de commits de historial.

## Datos verificados antes de empezar (solo lectura, sin clonar)

- La rama `spes-r-oss` declara `VERSION = 4`, `PATCHLEVEL = 19`, **`SUBLEVEL = 157`**: la misma versión que corre el teléfono (`4.19.157-perf`).
- El `defconfig` está en `arch/arm64/configs/vendor/`: `spes_defconfig`, `spes-perf_defconfig`, `bengal_defconfig`, `bengal-perf_defconfig`. El kernel del teléfono lleva `-perf` en su versión, así que el candidato es `vendor/spes-perf_defconfig`. **[VERIFICAR]** contra la configuración real del teléfono.
- El commit `cb1ffc010755` (el sufijo `gcb1ffc010755` de `uname -r`) devuelve **404 en GitHub**: Xiaomi compiló el kernel del teléfono desde un commit interno no publicado. El código abierto es lo más cercano, no una copia exacta.
- Último commit de la rama `spes-r-oss` (visto con `git ls-remote`): `88afd32564211f4cfb60171ed8cbeaa734860601`.

## Práctica guiada

```bash
# se completa con los comandos reales ejecutados
```

## Hallazgos reales

(se documentan aquí a medida que aparezcan)

## Evidencias

(se curan con "verifica img")

## Pendientes

- [ ] Clonar `spes-r-oss` en `src/kernel` y registrar el commit en `logs/04-commit.txt`.
- [ ] Confirmar `kernelversion` = `4.19.157`.
- [ ] Localizar `spes-perf_defconfig` en el árbol clonado.
- [ ] Buscar qué compilador y qué variables pide la rama (README, scripts, Makefile).
- [ ] Comparar el `defconfig` con la configuración real del teléfono (`/proc/config.gz`, si existe).
