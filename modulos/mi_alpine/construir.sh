#!/usr/bin/env bash
# Empaqueta Alpine minirootfs + tus archivos (overlay) como initramfs.
# uso: bash modulos/mi_alpine/construir.sh        (desde ~/Escritorio/Mobil)
# produce: out-initramfs/mi_alpine.cpio.gz   (o mi_alpine_tel.cpio.gz con el argumento "telefono")
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
NOMBRE=mi_alpine
EXTRAS="$AQUI/extras.lista"
if [ "${1:-}" = "telefono" ]; then               # variante del telefono: consola en pantalla (tty1)
	cp -a "$AQUI/telefono/." "$OUT/alpine/"
	NOMBRE=mi_alpine_tel
	EXTRAS="$AQUI/extras-tel.lista"
	rm -f "$OUT/alpine/init"; cp "$AQUI/telefono/init" "$OUT/alpine/init"; chmod 755 "$OUT/alpine/init"
	# firmware propietario del tactil (FocalTech): el driver lo pide a los ~2,7 s, antes de montar el disco.
	# Sale de backup/ (no se publica); si no esta, el initramfs se construye igual, sin tactil.
	FW=backup/super-extraido/fw
	if [ -d "$FW" ]; then mkdir -p "$OUT/alpine/lib/firmware"; cp "$FW"/*.bin "$OUT/alpine/lib/firmware/"; fi
fi
aarch64-linux-gnu-gcc -static -O2 -Wall -Wextra -o "$OUT/alpine/usr/local/bin/hog" "$AQUI/hog.c"   # tu programa de memoria
chmod 755 "$OUT/alpine/usr/local/bin/"* "$OUT/alpine/etc/init.d/"*
# gen_initramfs.sh llama a "usr/gen_init_cpio" con ruta RELATIVA: hay que ejecutarlo desde out-rust/
RAIZ=$(pwd)
( cd out-rust && sh "$RAIZ/$KSRC/usr/gen_initramfs.sh" -o "$RAIZ/$OUT/$NOMBRE.cpio" -u squash -g squash "$RAIZ/$OUT/alpine" "$RAIZ/$EXTRAS" )
gzip -9 -f "$OUT/$NOMBRE.cpio"
echo "initramfs: $(stat -c %s "$OUT/$NOMBRE.cpio.gz") bytes -> $OUT/$NOMBRE.cpio.gz"
echo "entradas: $(gzip -dc "$OUT/$NOMBRE.cpio.gz" | cpio -t 2>/dev/null | wc -l)"
