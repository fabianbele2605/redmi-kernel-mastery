#!/usr/bin/env bash
# Mide la lectura secuencial de /data con dos valores de read_ahead_kb, ALTERNANDOLOS.
#
# uso: bash artifacts/medir-readahead.sh <etiqueta> [repeticiones=3] [A_kb=512] [B_kb=2048] [MB=1024]
#   A = valor de partida (el que tiene el telefono), B = el valor que se prueba
#
# Requiere root en el telefono (KernelSU, modulo 13). Cambia SOLO /sys/block/dm-40/queue/read_ahead_kb
# y lo deja como estaba al terminar o si se interrumpe (trap).
# Produce logs/12-readahead-<etiqueta>.csv: orden, read_ahead_kb, ms, mb_s, quiet (temperatura de la zona quiet-therm, m°C)
set -u

etq="${1:?falta la etiqueta, p. ej.: bash artifacts/medir-readahead.sh r1}"
rep="${2:-3}"
A="${3:-512}"
B="${4:-2048}"
MB="${5:-1024}"
DEV=dm-40
out="logs/12-readahead-${etq}.csv"
F=/data/local/tmp/ra_test.bin

command -v adb >/dev/null || { echo "no encuentro adb"; exit 1; }
adb shell 'su -c id' 2>&1 | grep -q "uid=0" || { echo "no hay root en el telefono (su -c id falla)"; exit 1; }
[ -e "$out" ] && { echo "ya existe $out: usa otra etiqueta"; exit 1; }

original=$(adb shell "su -c 'cat /sys/block/$DEV/queue/read_ahead_kb'" | tr -d '\r')
echo "read_ahead_kb original de $DEV: $original KB (se restaurara al terminar)"

restaurar() {
  adb shell "su -c 'echo $original > /sys/block/$DEV/queue/read_ahead_kb'" >/dev/null 2>&1
  echo; echo "restaurado: $DEV read_ahead_kb = $(adb shell "su -c 'cat /sys/block/$DEV/queue/read_ahead_kb'" | tr -d '\r') KB"
}
trap restaurar EXIT

adb push artifacts/ra-una-lectura.sh /data/local/tmp/ra-una-lectura.sh >/dev/null
echo "preparando el archivo de prueba de $MB MB..."
adb shell "su -c 'dd if=/dev/zero of=$F bs=1M count=$MB 2>/dev/null; sync; ls -l $F'" | tr -d '\r'

temp() { adb shell "for d in /sys/class/thermal/thermal_zone*; do [ \"\$(cat \$d/type)\" = quiet-therm-usr ] && cat \$d/temp; done" | tr -d '\r'; }

echo "orden,read_ahead_kb,ms,mb_s,quiet" > "$out"
n=0
for i in $(seq 1 "$rep"); do
  for v in "$A" "$B"; do
    n=$((n + 1))
    r=$(adb shell "su -c 'sh /data/local/tmp/ra-una-lectura.sh $v $DEV'" | tr -d '\r' | tail -1)
    ra=${r% *}; ms=${r#* }
    mbs=$(( MB * 1000 / ms ))
    echo "$n,$ra,$ms,$mbs,$(temp)" | tee -a "$out"
  done
done
adb shell "su -c 'rm -f $F /data/local/tmp/ra-una-lectura.sh'" >/dev/null
echo "listo: $out"
