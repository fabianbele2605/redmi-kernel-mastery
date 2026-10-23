#!/usr/bin/env bash
# Empaqueta Alpine minirootfs + tus archivos (overlay) como initramfs.
# uso: bash modulos/mi_alpine/construir.sh        (desde ~/Escritorio/Mobil)
# produce: out-initramfs/mi_alpine.cpio.gz
set -eu
AQUI=modulos/mi_alpine
ROOT=src/alpine-rootfs                         # tar.gz de Alpine desempaquetado (verificado por hash)
OUT=out-initramfs
KSRC=src/linux-6.18.58
GEN_CPIO=out-rust/usr/gen_init_cpio            # compilado con el kernel de out-rust

[ -d "$ROOT" ] || { echo "falta $ROOT: desempaqueta alpine-minirootfs en esa carpeta"; exit 1; }
[ -x "$GEN_CPIO" ] || { echo "falta $GEN_CPIO"; exit 1; }
rm -rf "$OUT/alpine" && mkdir -p "$OUT"
cp -a "$ROOT" "$OUT/alpine"
cp -a "$AQUI/overlay/." "$OUT/alpine/"          # tus archivos pisan los de Alpine (p. ej. etc/inittab)
aarch64-linux-gnu-gcc -static -O2 -Wall -Wextra -o "$OUT/alpine/usr/local/bin/hog" "$AQUI/hog.c"   # tu programa de memoria
chmod 755 "$OUT/alpine/usr/local/bin/"* "$OUT/alpine/etc/init.d/"*
# gen_initramfs.sh llama a "usr/gen_init_cpio" con ruta RELATIVA: hay que ejecutarlo desde out-rust/
RAIZ=$(pwd)
( cd out-rust && sh "$RAIZ/$KSRC/usr/gen_initramfs.sh" -o "$RAIZ/$OUT/mi_alpine.cpio" -u squash -g squash "$RAIZ/$OUT/alpine" "$RAIZ/$AQUI/extras.lista" )
gzip -9 -f "$OUT/mi_alpine.cpio"
echo "initramfs: $(stat -c %s "$OUT/mi_alpine.cpio.gz") bytes -> $OUT/mi_alpine.cpio.gz"
echo "entradas: $(gzip -dc "$OUT/mi_alpine.cpio.gz" | cpio -t 2>/dev/null | wc -l)"
