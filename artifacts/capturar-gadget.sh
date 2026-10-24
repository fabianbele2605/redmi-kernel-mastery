#!/usr/bin/env bash
# Espera a que el telefono aparezca como gadget USB (1d6b:0104, serie "fabian-lab") y guarda lo que escriba
# por su puerto serie (el registro del kernel principal y un informe cada 5 s).
#
# uso: bash artifacts/capturar-gadget.sh [segundos=240] [salida=logs/14-gadget-serie.txt]
# Requiere poder leer /dev/ttyACM*: ver la regla de udev que se indica si no hay permiso.
set -u
dur="${1:-240}"
out="${2:-logs/14-gadget-serie.txt}"
[ -e "$out" ] && { echo "ya existe $out: usa otro nombre"; exit 1; }
: > "$out"
fin=$(( $(date +%s) + dur ))
echo "# captura del gadget USB, $(date '+%F %T'), hasta $dur s" >> "$out"
prev=""
while [ "$(date +%s)" -lt "$fin" ]; do
  usb=$(lsusb 2>/dev/null | grep -c "1d6b:0104")
  dev=$(ls /dev/ttyACM* 2>/dev/null | head -1)
  estado="gadget_usb=$usb puerto=${dev:-ninguno}"
  [ "$estado" != "$prev" ] && { echo "$(date +%H:%M:%S) $estado" | tee -a "$out"; prev="$estado"; }
  if [ -n "$dev" ]; then
    if [ ! -r "$dev" ]; then
      echo "$(date +%H:%M:%S) $dev existe pero NO se puede leer (permisos): ver regla de udev" | tee -a "$out"; sleep 2; continue
    fi
    stty -F "$dev" raw -echo 115200 2>/dev/null
    echo "$(date +%H:%M:%S) leyendo $dev ..." | tee -a "$out"
    timeout $(( fin - $(date +%s) )) cat "$dev" >> "$out" 2>/dev/null
    echo "$(date +%H:%M:%S) el puerto se cerro" | tee -a "$out"
  fi
  sleep 1
done
echo "# fin de la captura, $(date '+%F %T'); lineas: $(wc -l < "$out")" >> "$out"
