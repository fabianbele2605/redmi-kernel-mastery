# Módulo 3 — Copias de seguridad y recuperación

- Estado: Completado
- Fecha: 2026-10-06 a 2026-10-13
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
./fastboot.exe devices                  # [serial]  fastboot

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
10. **El reintento tras los ~166h funcionó sin repetir ningún trámite**: misma sesión de cuenta, mismo driver ya instalado, `fastboot devices` detectó el teléfono de inmediato. El botón pasó de decir "Unlock will erase user data" (antes) a mostrar dos avisos de confirmación con un contador de 3 y 2 segundos respectivamente (`Unlock anyway(3)` → `Unlock anyway(2)` → habilitado), forzando a leer el aviso antes de poder pulsar.
11. **El desbloqueo real sí borra todo y reinicia el teléfono al asistente de configuración de fábrica.** Hubo que reactivar Opciones de desarrollador y Depuración USB desde cero, igual que en el módulo 2. No hace falta SIM para completar el asistente; WiFi sí se puede usar sin restricción (la restricción de WiFi apagado/datos móviles era solo para vincular la cuenta en el módulo 3, no aplica aquí).
12. **Verificado con `adb` que el desbloqueo quedó reflejado en el sistema:** `ro.boot.flash.locked` pasó de `1` a `0`, y `ro.boot.verifiedbootstate` pasó de `green` a `orange`. El kernel sigue siendo el mismo stock (`4.19.157-perf-gcb1ffc010755`, nov 2023) — normal, todavía no se ha flasheado nada propio.

## Evidencias

**01 — Estado de Mi Desbloqueo: bloqueado, cuenta sin vincular**
Pantalla inicial del teléfono: "Dispositivo bloqueado, Teléfono asegurado" y botón "Agregar cuenta y dispositivo" aún sin tocar.
![Estado de Mi Desbloqueo antes de vincular la cuenta](evidencias/01-estado-mi-desbloqueo-bloqueado.png)

**02 — Cuenta vinculada con éxito (hallazgo #2)**
Toast "Agregado con éxito. La Cuenta Mi ya está asociada con este dispositivo" — la única señal real del cambio de estado; el texto de fondo de la pantalla no varía.
![Agregado con éxito](evidencias/03-agregado-con-exito.png)

**03 — Bug de la versión 6.5.224.28 (hallazgo #5)**
"Account Authentication" se queda en blanco indefinidamente tras iniciar sesión.
![Pantalla en blanco Account Authentication](evidencias/10-bug-account-authentication-blanco.png)

**04 — 403 Forbidden del CDN de Xiaomi (hallazgo #4)**
`ultimateota.d.miui.com` rechazando la descarga de `miflash_unlock_en_7.6.727.43.zip`; se repitió igual al intentarlo desde el actualizador interno de la app.
![403 Forbidden al descargar la version nueva](evidencias/11-403-forbidden-cdn-xiaomi.png)

**05 — Mirror alternativo: Internet Archive**
`archive.org`, item "Miflash unlock tool 7.6.602.42", usado para evitar el bloqueo del CDN de Xiaomi.
![Pagina de Internet Archive con la version 7.6.602.42](evidencias/13-internet-archive-7.6.602.42.png)

**06 — Driver de fastboot faltante (hallazgo #6)**
Administrador de dispositivos: "Android" sin controlador asignado bajo "Otros dispositivos", pese a que el teléfono ya estaba en FASTBOOT.
![Android sin driver en el Administrador de dispositivos](evidencias/16-device-manager-android-sin-driver.png)

**07 — Driver instalado correctamente (hallazgo #6)**
Apuntando manualmente a `...\driver\win10`: "Windows actualizó correctamente los controladores" → queda como "Android Bootloader Interface".
![Android Bootloader Interface instalado](evidencias/21-driver-instalado-android-bootloader-interface.png)

**08 — Mi Unlock detecta el teléfono**
Tras el driver, "Phone connected / Mi Phone", botón "Unlock" activo, advertencia de borrado de datos.
![Telefono conectado en Mi Unlock](evidencias/22-mi-unlock-telefono-conectado.png)

**09 — Resultado: rechazado por plazo de espera (hallazgos #7 y #8)**
"Couldn't unlock. Please unlock 166 hours later. And do not add your account in MIUI again..." — "Verifying device" en verde, "Unlocking" en rojo: no se llegó a borrar nada.
![Resultado del intento: 166 horas de espera](evidencias/26-resultado-166-horas-espera.png)

**10 — Desbloqueo real completado (hallazgo #10)**
"Unlocked successfully" — los tres pasos (Verifying device, Unlocking, Done) en verde, 2026-10-13, ya pasado el plazo de espera.
![Unlocked successfully](evidencias/27-unlocked-successfully.png)

*(La captura de terminal que verificaba `ro.boot.flash.locked=0` y `verifiedbootstate=orange` se descartó: mostraba el número de serie del teléfono en texto plano. El dato queda documentado igual en el hallazgo #12.)*

## Pendientes

- [x] Cuenta Mi iniciada y vinculada en el teléfono (Opciones de desarrollador → Estado de Mi Unlock).
- [x] Solicitud de Mi Unlock enviada y, tras el plazo de espera de 166 horas, completada con éxito el 2026-10-13.
- [x] Fastboot ROM descargada, misma fingerprint que `ro.build.fingerprint` del módulo 2, con su hash en `logs/03-hash-rom.txt`.
- [x] `boot.img`, `vendor_boot.img`, `dtbo.img`, `vbmeta.img`, `vbmeta_system.img` copiados a `backup/stock/` con hash en `logs/03-hash-stock.txt`.
- [x] Bootloader desbloqueado con Mi Unlock — confirmado con `ro.boot.flash.locked=0` y `verifiedbootstate=orange`.
- [x] Depuración USB reactivada tras el reseteo de fábrica.
- [x] `fastboot devices` y `fastboot getvar all` comprobados, guardados en `logs/03-fastboot-getvar.txt` (`anti:1`, `current-slot:b`, `product:spes`).
- [x] Procedimiento de rescate escrito en `logs/03-recuperacion.md`.
- [x] Verificar si `spes` tiene protección anti-rollback (hallazgo pendiente del módulo 2) antes de considerar cualquier downgrade — confirmado `anti:1`.
