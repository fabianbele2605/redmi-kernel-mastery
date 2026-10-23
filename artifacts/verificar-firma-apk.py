#!/usr/bin/env python3
"""Lee el bloque de firma v2 de un APK y muestra tamano y SHA-256 del primer certificado.
Solo LEE el archivo. uso: python3 -I apk_cert.py <archivo.apk>"""
import hashlib
import struct
import sys

V2_ID = 0x7109871A
V3_ID = 0xF05368C0
MAGIC = b"APK Sig Block 42"


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def u64(b, o):
    return struct.unpack_from("<Q", b, o)[0]


def main():
    data = open(sys.argv[1], "rb").read()
    # fin del directorio central (EOCD): buscar la firma 0x06054b50 desde el final
    eocd = data.rfind(b"PK\x05\x06")
    if eocd < 0:
        sys.exit("no se encuentra el EOCD: no parece un ZIP/APK")
    cd_off = u32(data, eocd + 16)
    if data[cd_off - 16:cd_off] != MAGIC:
        sys.exit("no hay bloque de firma APK (magic 'APK Sig Block 42' no encontrado)")
    blk_size = u64(data, cd_off - 24)
    blk_start = cd_off - blk_size - 8
    if u64(data, blk_start) != blk_size:
        sys.exit("tamano del bloque inconsistente")
    pos, end = blk_start + 8, cd_off - 24
    found = {}
    while pos < end:
        pair_len = u64(data, pos)
        pid = u32(data, pos + 8)
        found[pid] = data[pos + 12:pos + 8 + pair_len]
        pos += 8 + pair_len
    print("esquemas presentes:", ", ".join(hex(k) for k in found))
    for name, pid in (("v2", V2_ID), ("v3", V3_ID)):
        if pid not in found:
            print(f"{name}: no presente")
            continue
        v = found[pid]
        signers_len = u32(v, 0)
        s0_len = u32(v, 4)
        signed_len = u32(v, 8)
        sd = v[12:12 + signed_len]
        o = 0
        dig_len = u32(sd, o); o += 4 + dig_len                # digests
        certs_len = u32(sd, o); o += 4                        # certificates
        c0_len = u32(sd, o); o += 4
        cert = sd[o:o + c0_len]
        print(f"{name}: primer certificado = {c0_len} bytes (0x{c0_len:04x}), sha256 = {hashlib.sha256(cert).hexdigest()}")


main()
