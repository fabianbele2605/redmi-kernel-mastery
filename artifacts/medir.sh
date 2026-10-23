#!/usr/bin/env bash
# Muestrea temperatura y frecuencia del teléfono cada N segundos y lo guarda en un CSV.
#
# uso: bash artifacts/medir.sh <etiqueta> [segundos=60] [intervalo=5] [carga=0]
#   etiqueta:   nombre corto de la prueba, p. ej. "reposo" o "carga1"
#   segundos:   duración total de la medición
#   intervalo:  segundos entre muestras
#   carga:      segundos de carga (8 bucles vacíos, uno por núcleo) que el propio script
#               lanza a los 10 s de empezar; 0 = sin carga (medición en reposo)
#
# Produce logs/10-medicion-<etiqueta>.csv con columnas:
#   t_s, pmic, cpu_grande0, cpuss0, gpu, rf_pa, bateria, quiet, xo   (milésimas de °C: 37000 = 37,0 °C)
#   f_pequenos, f_grandes                                            (kHz, frecuencia actual de policy0 y policy4)
#   carga                                                            (1 = la carga estaba activa en esa muestra)
#
# Solo LEE /sys (la carga son bucles vacíos del usuario shell); no toca ninguna protección térmica.
# No contiene datos personales.
set -u

etq="${1:?falta la etiqueta, p. ej.: bash artifacts/medir.sh reposo}"
dur="${2:-60}"
paso="${3:-5}"
carga="${4:-0}"
INICIO_CARGA=10
out="logs/10-medicion-${etq}.csv"

command -v adb >/dev/null || { echo "no encuentro adb"; exit 1; }
adb get-state >/dev/null 2>&1 || { echo "no hay teléfono conectado"; exit 1; }

# Se ejecuta en el teléfono: z <tipo> imprime la temperatura de la zona con ese nombre.
REMOTO='z() { for d in /sys/class/thermal/thermal_zone*; do [ "$(cat $d/type)" = "$1" ] && cat $d/temp && return; done; echo NA; }; echo "$(z pm6125-tz),$(z cpu-1-0-usr),$(z cpuss-0-usr),$(z gpu-usr),$(z rf-pa1-therm-usr),$(z battery),$(z quiet-therm-usr),$(z xo-therm-usr),$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_cur_freq),$(cat /sys/devices/system/cpu/cpufreq/policy4/scaling_cur_freq)"'

# No sobrescribir: dos corridas con la misma etiqueta mezclarían sus filas en un solo CSV.
[ -e "$out" ] && { echo "ya existe $out: usa otra etiqueta o bórralo a propósito"; exit 1; }
echo "t_s,pmic,cpu_grande0,cpuss0,gpu,rf_pa,bateria,quiet,xo,f_pequenos,f_grandes,carga" > "$out"
inicio=$(date +%s)
echo "midiendo $dur s cada $paso s, carga=$carga s -> $out (no desconectes el teléfono)"

# Las muestras caen en tiempos fijos (0, paso, 2*paso...): cada llamada a adb tarda ~2 s,
# así que NO se puede hacer "leer; dormir paso" (el intervalo real saldría de paso + ~2 s).
n=0
t_carga=-1
# Si se corta con Ctrl+C, parar también los bucles del teléfono (su timeout es de $carga s y
# seguirían calentándolo sin que nadie los mida).
parar_carga() { adb shell 'pkill -f "while :"' >/dev/null 2>&1; echo; echo "interrumpido: carga detenida en el teléfono"; exit 130; }
trap parar_carga INT TERM
while :; do
  objetivo=$(( n * paso ))
  [ "$objetivo" -gt "$dur" ] && break
  ahora=$(( $(date +%s) - inicio ))
  [ "$ahora" -lt "$objetivo" ] && sleep $(( objetivo - ahora ))
  t=$(( $(date +%s) - inicio ))
  if [ "$carga" -gt 0 ] && [ "$t_carga" -lt 0 ] && [ "$t" -ge "$INICIO_CARGA" ]; then
    t_carga=$t
    adb shell "for i in 1 2 3 4 5 6 7 8; do timeout $carga sh -c 'while :; do :; done' & done; wait" >/dev/null 2>&1 &
  fi
  activa=0
  [ "$t_carga" -ge 0 ] && [ "$t" -ge "$t_carga" ] && [ "$t" -lt $(( t_carga + carga )) ] && activa=1
  fila=$(adb shell "$REMOTO" 2>/dev/null | tr -d '\r')
  echo "$t,$fila,$activa" | tee -a "$out"
  n=$(( n + 1 ))
done
wait
echo "listo: $(( $(wc -l < "$out") - 1 )) muestras en $out (la carga empezó en t=$t_carga s)"
