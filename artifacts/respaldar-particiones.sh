#!/usr/bin/env bash
# Copia a la laptop las particiones PROPIAS del telefono (las que no vuelven al flashear la ROM de fabrica)
# y verifica cada copia comparando su SHA-256 en el telefono con el de la laptop.
#
# uso: bash artifacts/respaldar-particiones.sh
# Requiere root en el telefono (KernelSU, modulo 13). SOLO LEE: no escribe nada en el telefono.
#
# Produce:
#   backup/particiones/<nombre>.img      (contienen IMEI, MAC, calibraciones: NO se publica; backup/ esta en .gitignore)
#   logs/14-hash-particiones.txt         (solo nombres y SHA-256: esto SI se versiona)
set -u

LISTA="persist modemst1 modemst2 fsg fsc devinfo misc frp keystore countrycode spunvm logfs apdp dip"
DIR=backup/particiones
MANIFIESTO=logs/14-hash-particiones.txt
BYNAME=/dev/block/bootdevice/by-name

command -v adb >/dev/null || { echo "no encuentro adb"; exit 1; }
adb shell 'su -c id' 2>&1 | grep -q "uid=0" || { echo "no hay root en el telefono (su -c id falla)"; exit 1; }
git check-ignore -q "$DIR/x" || { echo "ATENCION: $DIR no esta ignorado por Git; abortando para no publicar datos personales"; exit 1; }
mkdir -p "$DIR"
[ -e "$MANIFIESTO" ] && { echo "ya existe $MANIFIESTO: bórralo a propósito si quieres repetir"; exit 1; }

echo "# SHA-256 de particiones respaldadas ($(date '+%F %T')); las copias NO se publican" > "$MANIFIESTO"
fallos=0
for n in $LISTA; do
  dest="$DIR/$n.img"
  if [ -e "$dest" ]; then echo "$n: ya existe $dest, se omite"; continue; fi
  tam=$(adb shell "su -c 'blockdev --getsize64 $BYNAME/$n'" 2>/dev/null | tr -d '\r')
  adb exec-out "su -c 'dd if=$BYNAME/$n bs=1048576 2>/dev/null'" > "$dest"
  local_sha=$(sha256sum "$dest" | cut -d' ' -f1)
  remote_sha=$(adb shell "su -c 'sha256sum $BYNAME/$n'" | tr -d '\r' | cut -d' ' -f1)
  tam_local=$(stat -c %s "$dest")
  if [ "$local_sha" = "$remote_sha" ] && [ "$tam_local" = "$tam" ]; then
    printf "%-12s OK   %10s bytes  %s\n" "$n" "$tam_local" "${local_sha:0:16}…"
    echo "$local_sha  $n  $tam_local" >> "$MANIFIESTO"
  else
    printf "%-12s FALLO (local %s bytes %s... / telefono %s bytes %s...)\n" "$n" "$tam_local" "${local_sha:0:12}" "$tam" "${remote_sha:0:12}"
    fallos=$((fallos + 1)); rm -f "$dest"
  fi
done
echo "fallos: $fallos"
[ "$fallos" -eq 0 ]
