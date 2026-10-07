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
# Cuenta Mi: Ajustes > Opciones de desarrollador > Estado de Mi Desbloqueo >
# "Agregar cuenta y dispositivo" (requiere SIM + datos móviles, no WiFi)

# Mi Unlock (PC, Windows): descargado desde https://en.miui.com/unlock/download_en.html
# versión inicial 6.5.224.28 -> con bug conocido -> actualizada a 7.6.602.42
# (ver hallazgos). Login con cuenta Mi (Gmail como correo de la cuenta).

# Driver fastboot (Windows 11): Administrador de dispositivos > "Android" en
# Otros dispositivos > Actualizar controlador > Examinar mi PC >
#   rom\miflash_unlock_en_7.6.602.42\driver\win10   (con "Incluir subcarpetas")
# -> queda como "Android Bootloader Interface"

cd rom/miflash_unlock_en_7.6.602.42
./fastboot.exe devices                  # 2df43584  fastboot

# ROM fastboot (misma fingerprint que el módulo 2, V14.0.5.0.TGCMIXM):
# descargada completa (6.63 GB) tras descartar mirrors caídos/duplicados.
sha256sum "rom/spes_global_images_V14.0.5.0.TGCMIXM_..._92dfcefa88 (2).tgz" \
  | tee logs/03-hash-rom.txt

mkdir -p rom/extracted backup/stock
tar -xzf "rom/spes_global_images_V14.0.5.0.TGCMIXM_..._92dfcefa88 (2).tgz" -C rom/extracted
cp rom/extracted/*/images/{boot,vendor_boot,dtbo,vbmeta,vbmeta_system}.img backup/stock/
sha256sum backup/stock/* | tee logs/03-hash-stock.txt

# Intento de desbloqueo (teléfono en fastboot, batería 92%):
# Verifying device OK -> Unlocking rechazado por el servidor, SIN borrar datos.
```

## Hallazgos reales

1. **Xiaomi no publica oficialmente las fastboot ROM antiguas para descarga directa.** Solo existen índices/mirrors de terceros (xiaomirom.com, miuirom.org, mifirm.net) que reflejan el servidor de Xiaomi. `xiaomifirmwareupdater.com`, el índice más citado como fiable, **está caído/en venta** en este momento (2026-10-06).
2. **La página de "Estado de Mi Desbloqueo" del teléfono es texto instructivo estático, no un indicador de estado.** Los pasos 1-4 que muestra no cambian aunque la cuenta ya esté vinculada. La única señal real de éxito al asociar la cuenta fue un **toast emergente** ("Agregado con éxito..."), fácil de perder si no se mira en el momento exacto.
3. **Hay URLs viejas/rotas que parecen oficiales y no lo son:** `miui.com/unlock/apply.php` (foro roto, error de servidor) y `miui.com/unlock/index_en.html` (página de MIUI8, ~2016). La correcta y vigente es `en.miui.com/unlock/download_en.html`.
4. **El CDN de descarga de Xiaomi (`ultimateota.d.miui.com`) devuelve 403 Forbidden** al intentar bajar `miflash_unlock_en_7.6.727.43.zip`, tanto desde el navegador como desde el auto-actualizador integrado de la propia app. Es un bloqueo por IP/región confirmado en varios hilos de XDA, vigente en esta fecha; una VPN a EE. UU. **no lo resolvió**. Alternativa que sí funcionó: descargar una versión distinta (7.6.602.42) desde un archivo de Internet Archive.
5. **La versión 6.5.224.28 de Mi Unlock tiene un bug conocido:** tras iniciar sesión, la pantalla "Account Authentication" queda en blanco indefinidamente. Se resuelve actualizando a una versión más nueva (aquí: 7.6.602.42).
6. **Windows 11 no instala solo el driver de fastboot de Xiaomi.** Aunque el teléfono se veía físicamente en modo FASTBOOT, `fastboot devices` no devolvía nada y aparecía como "Android" sin controlador en "Otros dispositivos". El instalador incluido (`driver_install_64.exe`) no lo resolvió por sí solo; hubo que apuntar manualmente el asistente de controladores a la carpeta `driver\win10` de la propia herramienta (contiene `android_winusb.inf`). Tras eso quedó como "Android Bootloader Interface" y `fastboot devices` sí lo detectó.
7. **Mi Unlock no muestra el periodo de espera por adelantado.** La pantalla con el teléfono conectado decía simplemente "Unlock will erase user data" sin ningún contador, dando la impresión de que el borrado sería inmediato. El plazo de espera (166 horas, ≈ 7 días) solo apareció **después** de pulsar "Unlock" dos veces (dos avisos de confirmación encadenados) y de que el paso "Verifying device" pasara — el paso "Unlocking" fue rechazado por el servidor sin tocar los datos del teléfono.
8. **Advertencia explícita de Xiaomi:** si se vuelve a vincular la cuenta Mi en el teléfono (Agregar cuenta y dispositivo) antes de que termine la espera, el contador se reinicia desde cero. No tocar esa pantalla hasta pasado el plazo.
9. **`fastboot getvar all` confirma `anti:1`**, es decir, `spes` sí tiene protección anti-rollback activa. Cierra el "[VERIFICAR]" que había quedado abierto en el módulo 2: no se debe intentar un downgrade de firmware.

## Evidencias

(pendiente — se cura con "verifica img": capturas de Estado de Mi Desbloqueo, Mi Unlock con la cuenta vinculada, el error 403, el Administrador de dispositivos antes/después del driver, FASTBOOT en el teléfono, y la pantalla final "Couldn't unlock... 166 hours later")

## Pendientes

- [x] Cuenta Mi iniciada y vinculada en el teléfono (Opciones de desarrollador → Estado de Mi Unlock).
- [x] Solicitud de Mi Unlock enviada — **rechazada por plazo de espera: 166 horas desde 2026-10-06 (~2026-10-13)**. No volver a vincular la cuenta antes de esa fecha.
- [x] Fastboot ROM descargada, misma fingerprint que `ro.build.fingerprint` del módulo 2, con su hash en `logs/03-hash-rom.txt`.
- [x] `boot.img`, `vendor_boot.img`, `dtbo.img`, `vbmeta.img`, `vbmeta_system.img` copiados a `backup/stock/` con hash en `logs/03-hash-stock.txt`.
- [ ] Bootloader desbloqueado con Mi Unlock — pendiente hasta ~2026-10-13, reintentar con "Unlock again".
- [ ] Depuración USB reactivada tras el reseteo de fábrica (ocurrirá cuando el desbloqueo real se complete).
- [x] `fastboot devices` y `fastboot getvar all` comprobados, guardados en `logs/03-fastboot-getvar.txt` (`unlocked:no`, `anti:1`, `current-slot:b`, `product:spes`).
- [x] Procedimiento de rescate escrito en `logs/03-recuperacion.md`.
- [ ] Verificar si `spes` tiene protección anti-rollback (hallazgo pendiente del módulo 2) antes de considerar cualquier downgrade.
