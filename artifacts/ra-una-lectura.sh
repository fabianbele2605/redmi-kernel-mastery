#!/system/bin/sh
# Se ejecuta EN EL TELEFONO, como root: una lectura secuencial con la cache limpia.
# uso: sh ra-una-lectura.sh <read_ahead_kb> [dispositivo=dm-40]
# imprime: "<read_ahead_kb_efectivo> <milisegundos>"
RA=$1
DEV=${2:-dm-40}
F=/data/local/tmp/ra_test.bin
Q=/sys/block/$DEV/queue/read_ahead_kb
echo "$RA" > "$Q"
sync
echo 3 > /proc/sys/vm/drop_caches
s=$(date +%s%N)
dd if="$F" of=/dev/null bs=64k 2>/dev/null
e=$(date +%s%N)
echo "$(cat "$Q") $(( (e - s) / 1000000 ))"
