# Módulo 3 — Copias de seguridad, desbloqueo y recuperación

- Estado: En progreso
- Fecha: 2026-10-05
- Teléfono: Redmi Note 11 `spes`, MIUI `V14.0.5.0.TGCMIXM`, Android 13, A/B (slot `_b`), bootloader **bloqueado**
- Objetivo: tener, **antes de tocar nada**, la copia original de las particiones de arranque, el bootloader desbloqueado y un procedimiento de recuperación escrito y ensayado.

> Este es el único módulo del curso que **borra datos**: desbloquear el bootloader restablece el teléfono a fábrica.

## Concepto

Hay tres cosas distintas que proteger:

1. **Los datos del usuario**: el desbloqueo los borra. Se respaldan antes.
2. **La imagen original de arranque** (`boot`, `vendor_boot`, `dtbo`, `vbmeta*`): si un kernel propio no arranca, se restaura desde aquí. Se obtiene de la **ROM de fábrica exacta**, no de otra versión.
3. **El procedimiento de rescate**: escrito y ensayado (modo fastboot) antes de necesitarlo.

Xiaomi exige vincular una cuenta Mi al dispositivo y esperar un periodo (entre 24 y 168 horas) antes de permitir el desbloqueo. La espera la impone el servidor y no se puede saltar; por eso la vinculación se hace pronto y mientras tanto se avanza con los módulos 4 a 6, que no necesitan el teléfono desbloqueado.

## Plan del módulo

| Paso | Qué | Toca el teléfono |
|---|---|---|
| 1 | Datos a respaldar y requisitos (cuenta Mi, SIM con datos, espacio) | Solo lectura |
| 2 | Descargar la ROM de fábrica exacta y verificar su hash | No |
| 3 | Extraer `boot`, `vendor_boot`, `dtbo`, `vbmeta*` y guardar sus SHA-256 | No |
| 4 | Elegir la herramienta de desbloqueo (la oficial es solo Windows) | No |
| 5 | Vincular la cuenta Mi al dispositivo (inicia la espera) | Sí, ajustes |
| 6 | Desbloquear el bootloader tras la espera ⚠️ **borra datos** | Sí |
| 7 | Ensayo de modo fastboot, solo lectura | Sí |
| 8 | Escribir y revisar el procedimiento de recuperación | No |

## Datos verificados antes de empezar

- ROM: `spes_global_images_V14.0.5.0.TGCMIXM_20231128.0000.00_13.0_global_92dfcefa88.tgz`, 7,1 GB, publicada el 28 nov 2023 (la fecha coincide con la compilación del kernel del teléfono). Los primeros 10 caracteres del hash MD5 forman parte del nombre del archivo. ([XM Firmware Updater](https://xmfirmwareupdater.com/miui/spes/stable/V14.0.5.0.TGCMIXM/), [XiaomiROM](https://xiaomirom.com/en/download/redmi-note-11-spes-stable-V14.0.5.0.TGCMIXM/)) **[VERIFICAR]** el hash al descargar.
- La herramienta oficial **Mi Unlock es solo para Windows**; hay alternativas no oficiales para Linux. Un script de terceros que reciba las credenciales de la cuenta Mi es un riesgo, así que la elección se documenta antes de usar nada. ([Mi Flash Unlock Tool](https://drfone.wondershare.com/mi-account-unlock/mi-flash-unlock-review.html), [MiUnlockTool en XDA](https://xdaforums.com/t/tool-win-lin-mac-miunlocktool-unlock-bootloader-of-xiaomi-devices-on-mac-linux.3782444/page-10))
- Espera del desbloqueo: entre 24 y 168 horas, impuesta por el servidor de Xiaomi.
- **Para vincular la cuenta Mi hacen falta datos móviles:** una SIM insertada con un plan de datos activo y el Wi-Fi apagado; el Wi-Fi solo no basta. Algunos reportes añaden que la SIM debe tener el mismo número con el que se registró la cuenta. **[VERIFICAR]** ([guía de Mi Community](https://new.c.mi.com/global/post/101245), [Mi.com FAQ](https://www.mi.com/my/support/faq/details/KA-07238/))
- Datos del teléfono (Paso 1): `/data` 102 GB con 13 GB usados; batería 100 %. El teléfono es de laboratorio y no tiene datos que importen, así que **no se hace respaldo de datos**.
- **Paso 4 (decisión):** hay un PC con Windows disponible, así que el desbloqueo se hará con la **herramienta oficial Mi Unlock** y no con scripts de terceros en Linux. Las credenciales de la cuenta Mi solo se escriben en la herramienta oficial de Xiaomi. **[VERIFICAR]** la URL oficial de descarga al llegar al Paso 6.
- **La descarga de la ROM es lenta por diseño del servidor:** una conexión da ≈ 30 KB/s (≈ 2,5 días), pero 16 conexiones en paralelo dan ≈ 620 KB/s medidos (≈ 3 horas). Se usa `aria2c -x 16`. La Recovery ROM (3,7 GB) existe pero no sirve para rescatar el teléfono y no publica hash, así que se descarta como opción principal.
- Estado de partida (respuestas del usuario): **sin cuenta Mi y sin plan de datos en la SIM.** Hay que crear la cuenta y conseguir datos móviles antes del Paso 5; la vinculación es el camino crítico porque inicia la espera.

## Práctica guiada

```bash
# se completa con los comandos reales ejecutados
```

## Hallazgos reales

(se documentan aquí a medida que aparezcan)

## Evidencias

(se curan con "verifica img")

## Pendientes

- [x] Paso 1: datos a respaldar (ninguno), batería y espacio del teléfono.
- [ ] Crear una cuenta Mi con un correo dedicado al laboratorio.
- [ ] Conseguir una SIM con un plan de datos mínimo (solo hace falta durante la vinculación).
- [x] PC con Windows disponible: se usará Mi Unlock oficial (Paso 4 decidido).
- [ ] Paso 2: ROM descargada y hash verificado.
- [ ] Paso 3: imágenes originales copiadas a `backup/stock/` con sus SHA-256 en `logs/`.
- [x] Paso 4: herramienta de desbloqueo elegida (Mi Unlock oficial en Windows).
- [ ] Paso 5: cuenta Mi vinculada (anotar la fecha y hora de inicio de la espera).
- [ ] Paso 6: bootloader desbloqueado.
- [ ] Paso 7: ensayo de fastboot hecho.
- [ ] Paso 8: procedimiento de recuperación escrito.
- [ ] Comprobar si `spes` tiene protección anti-rollback antes de flashear nada.
