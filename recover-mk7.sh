#!/bin/sh
# WiFi Pineapple Mark VII — U-Boot Recovery Script
# Autor: lup1n

set -e

echo "======================================"
echo " Pineapple MK7 — U-Boot Recovery Tool "
echo "======================================"
echo

# --- Verificar root ---
if [ "$(id -u)" != "0" ]; then
    echo "[!] Este script debe ejecutarse como root"
    exit 1
fi

# --- Verificar archivos ---
UBOOT_BIN="/root/u-boot.bin"
ENV_BIN="/root/u-boot-env.bin"

if [ ! -f "$UBOOT_BIN" ]; then
    echo "[!] No se encontró $UBOOT_BIN"
    exit 1
fi

if [ ! -f "$ENV_BIN" ]; then
    echo "[!] No se encontró $ENV_BIN"
    exit 1
fi

echo "[+] Binarios encontrados"

# --- Mostrar particiones MTD ---
echo
echo "[*] Particiones MTD:"
cat /proc/mtd
echo

# --- Instalar kmod-mtd-rw si no está ---
if ! lsmod | grep -q mtd_rw; then
    echo "[*] Instalando kmod-mtd-rw..."
    opkg update
    opkg install kmod-mtd-rw
fi

# --- Cargar módulo con flag peligroso ---
echo "[*] Habilitando escritura en MTD críticos..."
insmod mtd-rw i_want_a_brick=1

# --- Crear backup ---
BACKUP_DIR="/root/mtd-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "[*] Creando backups en $BACKUP_DIR"

dd if=/dev/mtd1 of="$BACKUP_DIR/u-boot-env-backup.bin"
dd if=/dev/mtd0 of="$BACKUP_DIR/u-boot-backup.bin"

echo "[+] Backup completado"

# --- Confirmación ---
echo
echo "⚠️  ESTÁS A PUNTO DE REESCRIBIR U-BOOT ⚠️"
echo "Esto puede brickear permanentemente el dispositivo."
echo
printf "Escribe YES para continuar: "
read CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo "[!] Operación cancelada"
    exit 1
fi

# --- Flashear ---
echo
echo "[*] Flasheando u-boot-env (mtd1)..."
dd if="$ENV_BIN" of=/dev/mtd1

echo "[*] Flasheando u-boot (mtd0)..."
dd if="$UBOOT_BIN" of=/dev/mtd0

# --- Sincronizar ---
echo "[*] Sincronizando..."
sync

echo
echo "[✓] Recovery completado con éxito"
echo "[!] El dispositivo se reiniciará en 5 segundos..."

sleep 5
reboot
