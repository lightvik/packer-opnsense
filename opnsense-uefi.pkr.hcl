variable "ovmf_code" {
  type        = string
  default     = "/usr/share/edk2/ovmf/OVMF_CODE.fd"
  description = "OVMF_CODE.fd — прошивка (readonly)"
}

# ISO с config.xml создаётся entrypoint.sh перед запуском сборки
variable "config_iso" {
  type        = string
  default     = "/tmp/opnsense-config.iso"
  description = "ISO с конфигом OPNsense"
}

locals {
  iso_url = element(sort(fileset(".", "OPNsense-*-dvd-amd64.iso")), 0)
}

source "qemu" "opnsense" {
  qemu_binary         = "/usr/libexec/qemu-kvm"
  iso_url             = local.iso_url # нужен только Packer для валидации; в QEMU передаётся через qemuargs
  iso_checksum        = "none"
  output_directory    = "output"
  vm_name             = "opnsense.qcow2"
  format              = "qcow2"
  accelerator         = "kvm"
  disk_size           = "31G"
  memory              = 4096
  cpus                = 4
  disk_interface      = "virtio" # используется только для qemu-img create; в QEMU диск передаётся через qemuargs
  net_device          = "virtio-net"
  communicator        = "none"
  shutdown_timeout    = "40m"
  headless            = true
  use_default_display = false
  vnc_port_min        = 5959
  vnc_port_max        = 5959
  vnc_bind_address    = "127.0.0.1"
  machine_type        = "q35"

  # При использовании qemuargs Packer заменяет все свои дефолтные аргументы QEMU на наши.
  # Поэтому диск и CD-ROM нужно передавать явно — иначе они не попадут в команду запуска QEMU.
  qemuargs = [
    # UEFI-прошивка
    ["-drive", "if=pflash,format=raw,readonly=on,file=${var.ovmf_code}"],
    # Системный диск
    ["-drive", "file=output/opnsense.qcow2,if=virtio,cache=writeback,discard=ignore,format=qcow2"],
    # CD-ROM через virtio-scsi: installer ISO и config ISO с config.xml
    ["-device", "virtio-scsi-pci,id=scsi0"],
    ["-drive", "if=none,id=isoimg,media=cdrom,readonly=on,file=${local.iso_url}"],
    ["-device", "scsi-cd,drive=isoimg,bus=scsi0.0"],
    ["-drive", "if=none,id=cfgiso,media=cdrom,readonly=on,file=${var.config_iso}"],
    ["-device", "scsi-cd,drive=cfgiso,bus=scsi0.0"],
    ["-boot", "once=d"],
  ]

  boot_wait = "60s" # Ждём полной загрузки Live CD
  boot_command = [
    # Вводим логин установщика
    "installer<enter>",
    "<wait1s>",
    # Вводим пароль (по умолчанию: opnsense)
    "opnsense<enter>",
    "<wait3s>",
    # Выбор раскладки клавиатуры — принимаем по умолчанию
    "<enter>",
    "<wait2s>",
    # Главное меню: три стрелки вниз до пункта «Import config»
    "<down><down><down><enter>",
    "<wait2s>",
    # Выбор носителя с конфигом: (vtbd0 -> sr0 -> sr1)
    "<down><enter>",
    "<wait2s>",
    # Подтверждаем успешный импорт конфигурации
    "<enter>",
    "<wait2s>",
    # Главное меню: Install (ZFS)
    "<enter>",
    "<wait2>",
    # Тип ZFS-пула: stripe (по умолчанию)
    "<enter>",
    "<wait2>",
    # Выбор диска: отмечаем vtbd0 пробелом, затем OK
    "<spacebar>",
    "<enter>",
    "<wait2>",
    # Подтверждение о стирании диска
    "<left><enter>",
    "<wait5m>",
    # Финальный экран - выбираем «Complete Install»
    "<down><enter>",
    "<wait2>",
    # Отправляем OS команду выключения
    "<down><enter>",
  ]
}

build {
  sources = ["source.qemu.opnsense"]
}
