# Procedimiento de recuperación — spes

Copia original en `backup/stock/` (hashes en `logs/03-hash-stock.txt`):
`boot.img`, `vendor_boot.img`, `dtbo.img`, `vbmeta.img`, `vbmeta_system.img`.

ROM fastboot completa en `rom/spes_global_images_V14.0.5.0.TGCMIXM_...tgz`
(hash en `logs/03-hash-rom.txt`), descomprimida en `rom/extracted/`.

Slot activo confirmado en módulo 2: `_b` (A/B).

## a) Si entra en bootloop tras flashear

1. Mantener Vol- + Encendido para forzar entrada a fastboot.
2. Restaurar solo el boot:

   ```powershell
   cd N:\fabian\kernel_redmi\redmi-kernel-mastery\rom\miflash_unlock_en_7.6.602.42
   .\fastboot.exe flash boot_a backup\stock\boot.img
   .\fastboot.exe flash boot_b backup\stock\boot.img
   .\fastboot.exe flash vendor_boot_a backup\stock\vendor_boot.img
   .\fastboot.exe flash vendor_boot_b backup\stock\vendor_boot.img
   .\fastboot.exe reboot
   ```

   (Se flashea en ambos slots `_a` y `_b` porque no siempre se sabe cuál quedó activo tras un fallo.)

## b) Si no basta (sistema roto, no solo el boot)

Flashear la fastboot ROM completa desde `rom/extracted/.../images/` con la
herramienta oficial **MiFlash** (no `flash_all_lock.bat`/`.sh` — ese vuelve a
**bloquear** el bootloader) o `flash_all.bat` / `flash_all.sh` desde esa misma
carpeta, que no bloquea.

## c) Verificación previa

```powershell
.\fastboot.exe getvar current-slot
.\fastboot.exe getvar unlocked
```
