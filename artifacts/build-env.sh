# uso: source artifacts/build-env.sh
#
# Por defecto compila el árbol oficial de Xiaomi (src/kernel -> out/).
# Para otro árbol, define KSRC y KOUT ANTES de hacer source, por ejemplo:
#   export KSRC="$HOME/Escritorio/Mobil/src/kernel-px"
#   export KOUT="$HOME/Escritorio/Mobil/out-px"
#   source artifacts/build-env.sh

export LAB="$HOME/Escritorio/Mobil"
export KSRC="${KSRC:-$LAB/src/kernel}"
export KOUT="${KOUT:-$LAB/out}"
export PATH="$LAB/tools/clang-r383902/bin:$PATH"

kmake() {
  make -C "$KSRC" O="$KOUT" ARCH=arm64 \
    CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm \
    OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    "$@"
}

echo "kernel: $KSRC"
echo "salida: $KOUT"
