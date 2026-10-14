# uso: source artifacts/build-env.sh
export LAB="$HOME/Escritorio/Mobil"
export PATH="$LAB/tools/clang-r383902/bin:$PATH"

kmake() {
  make -C "$LAB/src/kernel" O="$LAB/out" ARCH=arm64 \
    CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm \
    OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    "$@"
}
