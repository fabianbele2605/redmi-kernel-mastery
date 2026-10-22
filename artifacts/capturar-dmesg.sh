#!/usr/bin/env bash
# Captura el registro del kernel del teléfono conectado y lo deja listo para versionar.
#
# uso: bash artifacts/capturar-dmesg.sh <etiqueta>
#   etiqueta: nombre corto de la prueba, p. ej. "fabrica" o "uvite"
#
# Produce:
#   backup/bugreport-<etiqueta>.zip   (datos personales: NO se publica; la carpeta backup/ está ignorada por Git)
#   logs/08-dmesg-<etiqueta>.txt      (solo el registro del kernel, con identificadores tapados)
#
# Antes de dejarlo en logs/ hace una PRUEBA DE FUGAS; si encuentra el serial, un
# PARTUUID, un UUID, un número de 15 dígitos o una MAC, BORRA la salida y termina con error.
set -u

etq="${1:?falta la etiqueta, p. ej.: bash artifacts/capturar-dmesg.sh uvite}"
zip="backup/bugreport-${etq}.zip"
out="logs/08-dmesg-${etq}.txt"

command -v adb >/dev/null || { echo "no encuentro adb"; exit 1; }
adb wait-for-device

printf "esperando a que Android termine de arrancar"
for _ in $(seq 1 60); do
  [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && break
  printf "."; sleep 3
done
echo
echo "kernel en marcha: $(adb shell uname -r | tr -d '\r')"
echo "dejando 20 s para que los servicios se asienten..."; sleep 20

adb bugreport "$zip" || { echo "FALLO: adb bugreport"; exit 1; }
python3 artifacts/extraer-dmesg.py "$zip" "$out" || exit 1

# --- prueba de fugas -------------------------------------------------------
ser="$(adb get-serialno | tr -d '\r')"
f_serial=$(grep -c -F -- "$ser" "$out")
f_partuuid=$(grep -c -E "PARTUUID=[0-9a-fA-F]" "$out")
f_uuid=$(grep -c -E "\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b" "$out")
f_imei=$(grep -c -E "\b[0-9]{15}\b" "$out")
f_mac=$(grep -c -E "\b([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}\b" "$out")
echo "prueba de fugas -> serial:$f_serial  PARTUUID:$f_partuuid  UUID:$f_uuid  15-dígitos:$f_imei  MAC:$f_mac"
if [ $((f_serial + f_partuuid + f_uuid + f_imei + f_mac)) -ne 0 ]; then
  rm -f "$out"
  echo "FUGAS DETECTADAS: se borró $out. No lo subas; avisa al mentor."
  exit 2
fi

# --- resumen ---------------------------------------------------------------
echo "--- resumen de $out"
echo "líneas:                 $(wc -l < "$out")"
for n in 3 4 6; do
  printf "nivel <%s>:             %s\n" "$n" "$(grep -c "^<$n>" "$out")"
done
printf "<3> sin charla de batería: %s\n" "$(grep '^<3>' "$out" | grep -v -E 'fg_|nopmi_chg|sm5602|_calculate_battery|bq[0-9]|USBPD|xm_pd' | wc -l)"
printf "denegaciones SELinux:   %s\n" "$(grep -c 'avc: denied' "$out")"
echo "banner:"; grep -m1 "Linux version" "$out" | cut -c1-120
echo "listo. (el .zip con datos personales queda en $zip, que Git ignora)"
