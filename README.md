# packer-opnsense

Packer-шаблон для автоматической установки OPNsense в образ диска qcow2.

Загружает DVD-установщик OPNsense в QEMU, через второй CD-ROM подкладывает `config.xml`, проводит установку в автоматическом режиме и сохраняет готовый образ в `output/opnsense.qcow2`.

## Как это работает

1. Packer запускает DVD ISO OPNsense в QEMU с аппаратным ускорением KVM.
2. Второй виртуальный CD-ROM с меткой `OPNSENSE_CONFIG` содержит `config.xml` — установщик OPNsense подхватывает его автоматически.
3. `boot_command` управляет меню установщика: раскладка клавиатуры → импорт конфига → ZFS stripe → выключение.
4. Готовый образ сохраняется в `output/opnsense.qcow2`.

Всё выполняется внутри Docker-контейнера (`ghcr.io/lightvik/packer-opnsense:latest`), в котором уже есть Packer и QEMU. На хосте нужны только Docker и `/dev/kvm`.

## Требования

- Linux-хост с включённым KVM (доступен `/dev/kvm`)
- Docker

## Быстрый старт

1. Положить ISO-образ OPNsense в корень проекта (шаблон имени: `OPNsense-*-dvd-amd64.iso`).
2. Положить `config.xml` в корень проекта.
3. Запустить сборку:

```bash
./run.sh build opnsense.pkr.hcl
```

Образ будет записан в `output/opnsense.qcow2`.

### Наблюдение за установкой через VNC

Во время сборки консоль доступна по VNC на `127.0.0.1:5959`. Подключиться можно любым VNC-клиентом.

## Файлы проекта

| Файл | Назначение |
|---|---|
| `opnsense.pkr.hcl` | Основной Packer-шаблон (источник QEMU + автоматизация загрузки) |
| `plugins.pkr.hcl` | Зависимости плагинов Packer (плагин QEMU) |
| `config.xml` | Конфигурация OPNsense, инжектируемая через CD-ROM (не коммитится) |
| `run.sh` | Обёртка: монтирует каталог проекта и запускает Packer внутри Docker |
| `Dockerfile` | Образ с Packer + QEMU для CI и локальных сборок |

## Docker-образ

Образ среды сборки публикуется в GHCR:

```
ghcr.io/lightvik/packer-opnsense:latest
```

Новый образ публикуется при каждом git-теге в формате `vX.Y.Z`.

## CI

GitHub Actions выполняет линтинг Dockerfile при каждом push/PR и публикует образ в GHCR при создании тега.
