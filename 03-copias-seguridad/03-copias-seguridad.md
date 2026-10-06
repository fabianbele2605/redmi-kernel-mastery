# Módulo 3 — Copias de seguridad y recuperación

- Estado: En progreso
- Fecha: 2026-10-06
- Versión: Android 13, MIUI 14 V14.0.5.0.TGCMIXM, kernel `4.19.157-perf-gcb1ffc010755` (ver [módulo 2](../02-identificar-telefono/02-identificar-telefono.md))
- Objetivo: tener cómo volver al estado original del teléfono antes de desbloquear el bootloader y antes de flashear nada. Vincular la cuenta Mi, descargar la fastboot ROM exacta (misma fingerprint), extraer y guardar el `boot.img` original con su hash, y dejar escrito el procedimiento de rescate.

## Concepto

Desbloquear el bootloader de un Xiaomi borra todos los datos del teléfono (`fastboot erase userdata` / wipe de fábrica) y no se puede deshacer sin volver a bloquear. Antes de pedir el desbloqueo hay que:

1. Respaldar lo que importe del teléfono (fotos, chats, apps).
2. Vincular la cuenta Mi en el teléfono y comprobar el estado de Mi Desbloqueo.
3. Descargar la fastboot ROM **exacta** (misma fingerprint que ya se confirmó en el módulo 2: `V14.0.5.0.TGCMIXM`), para poder reconstruir el teléfono entero si algo sale mal, no solo el `boot.img`.
4. Extraer `boot.img` (y `vendor_boot`, `dtbo`, `vbmeta` si existen) y guardar su hash SHA-256, porque en el módulo 7 se va a sustituir justo esa imagen.
5. Escribir el procedimiento de rescate **antes** de necesitarlo, no después.

Xiaomi impone un periodo de espera para Mi Unlock que puede ser de días; mientras se espera se puede avanzar con los módulos 4-6 (no tocan el teléfono).

## Práctica guiada

```bash
# se completa durante el módulo
```

## Hallazgos reales

1. (pendiente)

## Evidencias

(pendiente)

## Pendientes

- [ ] Cuenta Mi iniciada y vinculada en el teléfono (Opciones de desarrollador → Estado de Mi Unlock).
- [ ] Solicitud de Mi Unlock enviada (anotar fecha de solicitud, por el periodo de espera).
- [ ] Fastboot ROM descargada, misma fingerprint que `ro.build.fingerprint` del módulo 2, con su hash en `logs/03-hash-rom.txt`.
- [ ] `boot.img` (y `vendor_boot`/`dtbo`/`vbmeta` si existen) copiados a `backup/stock/` con hash en `logs/03-hash-stock.txt`.
- [ ] Bootloader desbloqueado con Mi Unlock.
- [ ] Depuración USB reactivada tras el reseteo de fábrica.
- [ ] `fastboot devices` y `fastboot getvar all` comprobados, guardados en `logs/03-fastboot-getvar.txt`.
- [ ] Procedimiento de rescate escrito en `logs/03-recuperacion.md`.
- [ ] Verificar si `spes` tiene protección anti-rollback (hallazgo pendiente del módulo 2) antes de considerar cualquier downgrade.
