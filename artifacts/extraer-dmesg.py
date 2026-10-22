#!/usr/bin/env python3
"""Extrae el registro del kernel de un `adb bugreport` y lo deja SIN datos personales.

Uso:
    python3 artifacts/extraer-dmesg.py <bugreport.zip> <salida.txt>

Del bugreport solo se copian estas secciones:
  - KERNEL LOG (dmesg)
  - LAST KMSG (el registro del arranque anterior, vía pstore, si existe)

Todo lo demás (cuentas, redes Wi-Fi, apps, IMEI...) NO se toca ni se copia.
Además se tapan los identificadores que pueden aparecer dentro del propio dmesg
(número de serie, IMEI/MEID, direcciones MAC, UID de CPU, PARTUUID y UUID de particiones) antes de escribir la salida.
Solo LEE el zip; no modifica nada.
"""
import re
import sys
import zipfile

SECCIONES = ("KERNEL LOG", "LAST KMSG")

# (patrón, reemplazo)
TAPAR = [
    (re.compile(r"(androidboot\.(?:serialno|cpuid|meid|imei[0-9]*|wifimacaddr|btmacaddr)=)\S+", re.I), r"\1[TAPADO]"),
    (re.compile(r"(serialno=)\S+", re.I), r"\1[TAPADO]"),
    (re.compile(r"(PARTUUID=)[0-9A-Fa-f-]{8,}", re.I), r"\1[TAPADO]"),
    (re.compile(r"\b([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\b", re.I), "[UUID-TAPADO]"),
    (re.compile(r"\b([0-9A-Fa-f]{2}(?::[0-9A-Fa-f]{2}){5})\b"), "[MAC-TAPADA]"),
    (re.compile(r"\b(\d{15})\b"), "[IMEI?-TAPADO]"),
]


def tapar(linea: str) -> str:
    for patron, reemplazo in TAPAR:
        linea = patron.sub(reemplazo, linea)
    return linea


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    ruta_zip, salida = sys.argv[1], sys.argv[2]

    with zipfile.ZipFile(ruta_zip) as z:
        txt = [n for n in z.namelist() if n.startswith("bugreport-") and n.endswith(".txt")]
        if not txt:
            sys.exit("No encuentro bugreport-*.txt dentro del zip. Contenido: " + ", ".join(z.namelist()[:8]))
        lineas = z.read(txt[0]).decode("utf-8", errors="replace").splitlines()

    dentro = False
    trozos = []
    for linea in lineas:
        encabezado = re.match(r"^------ (.+)", linea)
        if encabezado:
            titulo = encabezado.group(1)
            if any(titulo.startswith(s) for s in SECCIONES):
                dentro = True
                trozos.append(f"\n===== {tapar(titulo)} =====")
                continue
            dentro = False
        if dentro:
            trozos.append(tapar(linea))

    if not trozos:
        sys.exit("No se encontró ninguna sección KERNEL LOG ni LAST KMSG en " + txt[0])

    with open(salida, "w", encoding="utf-8") as f:
        f.write("\n".join(trozos) + "\n")
    print(f"escrito {salida}: {len(trozos)} líneas (de {txt[0]})")


if __name__ == "__main__":
    main()
