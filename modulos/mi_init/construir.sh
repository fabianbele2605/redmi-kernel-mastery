#!/usr/bin/env bash
# Compila mi_init.c para ARM64 (estatico) y lo empaqueta como initramfs.
# uso: bash modulos/mi_init/construir.sh          (desde ~/Escritorio/Mobil)
# produce: out-initramfs/mi_init.cpio.gz
set -eu
AQUI=modulos/mi_init
OUT=out-initramfs
GEN=out-rust/usr/gen_init_cpio      # del arbol del kernel 6.18.58 (modulo 11)

[ -x "$GEN" ] || { echo "falta $GEN (compila el kernel de out-rust primero)"; exit 1; }
mkdir -p "$OUT"
for p in mi_init hijo; do
	aarch64-linux-gnu-gcc -static -O2 -Wall -Wextra -o "$OUT/$p" "$AQUI/$p.c"
	aarch64-linux-gnu-strip "$OUT/$p"
done
( cd "$OUT" && "../$GEN" "../$AQUI/initramfs.lista" | gzip -9 > mi_init.cpio.gz )
echo "mi_init:   $(stat -c %s "$OUT/mi_init") bytes ($(file -b "$OUT/mi_init" | cut -d, -f1-2))"
echo "hijo:      $(stat -c %s "$OUT/hijo") bytes"
echo "initramfs: $(stat -c %s "$OUT/mi_init.cpio.gz") bytes -> $OUT/mi_init.cpio.gz"
echo "contenido:"; gzip -dc "$OUT/mi_init.cpio.gz" | cpio -t 2>/dev/null
