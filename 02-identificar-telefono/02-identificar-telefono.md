# Módulo 2 — Identificar el teléfono

- Estado: En progreso
- Fecha: 2026-10-05
- Teléfono: Xiaomi Redmi Note 11 (codename esperado `spes` / `spesn`)
- Objetivo: confirmar con comandos, y no por suposición, qué teléfono es, qué Android/MIUI y kernel lleva, si es A/B y en qué estado está el bootloader. Todo en **solo lectura**: no se modifica nada del teléfono.

## Concepto

"Redmi Note 11" es el nombre comercial de varios teléfonos distintos: el 4G con Snapdragon 680 (`spes`/`spesn`) usa las fuentes de `spes-r-oss`, pero las variantes con chip MediaTek tienen otro kernel y otro árbol. Usar el árbol equivocado produce imágenes que no arrancan. Por eso este módulo es una **puerta de seguridad**: si el codename o la plataforma no coinciden, el curso se detiene aquí.

`adb` (Android Debug Bridge) habla con Android ya arrancado, y `getprop` lee las propiedades del sistema. Cada dato se contrasta contra lo esperado:

| Propiedad | Valor esperado |
|---|---|
| `ro.product.device` | `spes` o `spesn` |
| `ro.board.platform` | `bengal` (Snapdragon 680) |
| `uname -a` | kernel 4.19.x, arquitectura aarch64 |
| `ro.boot.slot_suffix` | vacío (no A/B) o `_a`/`_b` (A/B) |
| `ro.boot.flash.locked` | `1` = bootloader bloqueado |

## Práctica guiada

```bash
# se completa con los comandos reales ejecutados
```

## Hallazgos reales

(se documentan aquí a medida que aparezcan)

## Evidencias

(se curan con "verifica img")

## Pendientes

- [ ] Activar opciones de desarrollador y depuración USB en el teléfono.
- [ ] `adb devices`: el PC ve el teléfono y se acepta la huella RSA.
- [ ] Confirmar codename, plataforma, Android/MIUI y kernel.
- [ ] Averiguar si es A/B y si el bootloader está bloqueado.
- [ ] Completar la ficha técnica del teléfono.
- [ ] Tapar serial, IMEI y cuenta Mi en toda captura antes de subirla.
