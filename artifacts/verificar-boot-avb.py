#!/usr/bin/env python3
"""Comprueba si una imagen de arranque coincide con el hash que firma vbmeta.

Uso:
    python3 artifacts/verificar-boot-avb.py <imagen> [particion] [log_vbmeta]

    imagen      boot.img (o vendor_boot.img, dtbo.img...) a comprobar
    particion   nombre del descriptor en vbmeta (por defecto: boot)
    log_vbmeta  salida de `avbtool info_image` (por defecto: logs/06-vbmeta-info.txt)

AVB calcula: SHA256( salt || primeros <Image Size> bytes de la imagen ).
Solo lee archivos; no modifica nada.
"""
import hashlib
import re
import sys


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    imagen = sys.argv[1]
    particion = sys.argv[2] if len(sys.argv) > 2 else "boot"
    log = sys.argv[3] if len(sys.argv) > 3 else "logs/06-vbmeta-info.txt"

    texto = open(log, encoding="utf-8").read()
    patron = (r"Hash descriptor:\s+Image Size:\s+(\d+) bytes.*?"
              r"Partition Name:\s+" + re.escape(particion) +
              r"\s+Salt:\s+([0-9a-f]+)\s+Digest:\s+([0-9a-f]+)")
    m = re.search(patron, texto, re.S)
    if not m:
        sys.exit(f"No hay un 'Hash descriptor' para '{particion}' en {log}")
    tam, salt, esperado = int(m.group(1)), m.group(2), m.group(3)

    datos = open(imagen, "rb").read()
    if len(datos) < tam:
        sys.exit(f"{imagen} mide {len(datos)} bytes y vbmeta espera al menos {tam}")
    calculado = hashlib.sha256(bytes.fromhex(salt) + datos[:tam]).hexdigest()

    print(f"imagen:      {imagen}")
    print(f"partición:   {particion}   (vbmeta cubre los primeros {tam} bytes)")
    print(f"esperado:    {esperado}")
    print(f"calculado:   {calculado}")
    print("RESULTADO:  ", "COINCIDE con vbmeta" if calculado == esperado
          else "NO coincide (con el bootloader desbloqueado, AVB avisa pero deja arrancar)")


if __name__ == "__main__":
    main()
