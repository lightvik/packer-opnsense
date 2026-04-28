# packer-opnsense

Packer-шаблон для автоматической установки OPNsense в qcow2-образ через QEMU/KVM.

Загружает DVD ISO в QEMU, инжектирует `config.xml` через второй CD-ROM, проводит установку в автоматическом режиме (ZFS stripe) и сохраняет результат в `output/opnsense.qcow2`.

## Требования

- Linux-хост с KVM (`/dev/kvm`)
- Docker

## Быстрый старт

1. Положить ISO в корень проекта (`OPNsense-*-dvd-amd64.iso`)
2. Положить `config.xml` в корень проекта
3. Запустить:

```bash
docker run \
  --rm \
  --device /dev/kvm \
  --network=host \
  --volume "$(pwd):/workspace" \
  ghcr.io/lightvik/packer-opnsense:latest \
  build .
```

> VNC-консоль установщика доступна на `127.0.0.1:5959` во время сборки.

## Файлы

| Файл | Назначение |
|---|---|
| `opnsense.pkr.hcl` | Packer-шаблон: QEMU-источник и автоматизация установки |
| `plugins.pkr.hcl` | Зависимости плагинов Packer |
| `config.xml` | Конфигурация OPNsense, инжектируемая через CD-ROM (не коммитится) |
| `Dockerfile` | Образ с Packer и QEMU |

## CI

При push в `master` — линтинг Dockerfile и HCL-файлов.  
При теге `vX.Y.Z` — линтинг + сборка и публикация образа в `ghcr.io/lightvik/packer-opnsense`.
