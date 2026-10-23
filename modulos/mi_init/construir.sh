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
aarch64-linux-gnu-gcc -static -O2 -Wall -Wextra -o "$OUT/mi_init" "$AQUI/mi_init.c"
aarch64-linux-gnu-strip "$OUT/mi_init"
( cd "$OUT" && "../$GEN" "../$AQUI/initramfs.lista" | gzip -9 > mi_init.cpio.gz )
echo "binario:   $(stat -c %s "$OUT/mi_init") bytes ($(file -b "$OUT/mi_init" | cut -d, -f1-2))"
echo "initramfs: $(stat -c %s "$OUT/mi_init.cpio.gz") bytes -> $OUT/mi_init.cpio.gz"
echo "contenido:"; gzip -dc "$OUT/mi_init.cpio.gz" | cpio -t 2>/dev/null
