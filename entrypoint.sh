#!/bin/bash
set -euo pipefail

# ── helpers ──────────────────────────────────────────────────────────────────

log()  { echo "[packer-opnsense] $*"; }
die()  { echo "[packer-opnsense] ERROR: $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

usage() {
  echo "Usage: $(basename "$0") <bios|uefi>" >&2
  exit 1
}

# ── validate args ─────────────────────────────────────────────────────────────

[[ $# -eq 1 ]] || usage

FIRMWARE="${1,,}"   # lowercase

[[ "$FIRMWARE" == "bios" || "$FIRMWARE" == "uefi" ]] || usage

# ── bios ──────────────────────────────────────────────────────────────────────

run_bios() {
  step "Запуск BIOS-сборки"
  exec packer build opnsense-bios.pkr.hcl
}

# ── uefi ──────────────────────────────────────────────────────────────────────

build_config_iso() {
  local config_xml=/workspace/config.xml
  local cfg_root=/tmp/cfg_root
  local iso=/tmp/opnsense-config.iso

  [[ -f "$config_xml" ]] || die "config.xml не найден: $config_xml"

  step "Создание config ISO"
  log "Источник: $config_xml"

  rm -rf "$cfg_root"
  mkdir -p "$cfg_root/conf"
  cp "$config_xml" "$cfg_root/conf/config.xml"

  xorriso -as mkisofs -V OPNSENSE_CONFIG -o "$iso" "$cfg_root" \
    > /dev/null 2>&1

  log "ISO готов: $iso"
}

run_uefi() {
  build_config_iso
  step "Запуск UEFI-сборки"
  exec packer build opnsense-uefi.pkr.hcl
}

# ── main ──────────────────────────────────────────────────────────────────────

log "Прошивка: ${FIRMWARE^^}"

case "$FIRMWARE" in
  bios) run_bios ;;
  uefi) run_uefi ;;
esac
