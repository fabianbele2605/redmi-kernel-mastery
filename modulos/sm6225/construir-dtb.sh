#!/usr/bin/env bash
# Compila el DTB de laboratorio (RAM de 3 GiB + ramoops) del kernel principal del SM6225.
# uso: bash modulos/sm6225/construir-dtb.sh        (desde ~/Escritorio/Mobil)
# produce: out-sm6225/lab.dtb
set -eu
K=src/linux-sm6225
D=$K/arch/arm64/boot/dts/qcom
cp modulos/sm6225/sm6225-xiaomi-spes-sm5602-lab.dts "$D/"
trap 'rm -f "$D/sm6225-xiaomi-spes-sm5602-lab.dts"' EXIT
( cd "$K" && cpp -nostdinc -I arch/arm64/boot/dts -I arch/arm64/boot/dts/qcom -I include -undef -D__DTS__ \
    -x assembler-with-cpp arch/arm64/boot/dts/qcom/sm6225-xiaomi-spes-sm5602-lab.dts \
  | dtc -I dts -O dtb -@ -o "$OLDPWD/out-sm6225/lab.dtb" - )
echo "lab.dtb: $(stat -c %s out-sm6225/lab.dtb) bytes"
