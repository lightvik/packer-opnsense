# packer-opnsense

Packer-шаблон для автоматической установки OPNsense в qcow2-образ через QEMU/KVM.

Загружает DVD ISO в QEMU, инжектирует `config.xml` через второй CD-ROM, проводит установку в автоматическом режиме (ZFS stripe) и сохраняет результат в `output/opnsense.qcow2`.

Протестировано с OPNsense **26.1.6**.

## Требования

- Linux-хост с KVM (`/dev/kvm`)
- Docker

## Быстрый старт

1. Положить ISO в корень проекта (`OPNsense-*-dvd-amd64.iso`)
2. Положить `config.xml` в корень проекта
3. Запустить, передав тип прошивки первым аргументом: `bios` или `uefi`

```bash
docker run \
  --rm \
  --device /dev/kvm \
  --network=host \
  --volume "$(pwd):/workspace" \
  ghcr.io/lightvik/packer-opnsense:latest \
  uefi
```

> VNC-консоль установщика доступна на `127.0.0.1:5959` во время сборки.

## Файлы

| Файл | Назначение |
|---|---|
| `opnsense-bios.pkr.hcl` | Packer-шаблон для BIOS (SeaBIOS) |
| `opnsense-uefi.pkr.hcl` | Packer-шаблон для UEFI (EDK2-OVMF) |
| `plugins.pkr.hcl` | Зависимости плагинов Packer |
| `entrypoint.sh` | Точка входа: создаёт config ISO (UEFI) и запускает packer |
| `config.xml` | Конфигурация OPNsense, инжектируемая через CD-ROM (не коммитится) |
| `Dockerfile` | Образ с Packer, QEMU и OVMF на базе Oracle Linux 10 |

## CI

При push в `master` — линтинг Dockerfile и HCL-файлов.  
При теге `vX.Y.Z` — линтинг + сборка и публикация образа в `ghcr.io/lightvik/packer-opnsense`.
