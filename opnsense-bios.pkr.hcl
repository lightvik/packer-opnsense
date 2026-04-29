locals {
  # Автоматически находит ISO-файл установщика OPNsense в текущей директории
  iso_url = element(sort(fileset(".", "OPNsense-*-dvd-amd64.iso")), 0)
}

source "qemu" "opnsense" {
  qemu_binary         = "/usr/libexec/qemu-kvm" # Путь к бинарнику QEMU - задан явно т.к. внутри docker не может найти в $PATH
  iso_url             = local.iso_url           # Путь к ISO-образу установщика
  iso_checksum        = "none"                  # Контрольная сумма ISO (none — пропустить проверку)
  output_directory    = "output"                # Директория для сохранения готового образа
  vm_name             = "opnsense.qcow2"        # Имя выходного файла образа
  format              = "qcow2"                 # Формат выходного образа диска
  accelerator         = "kvm"                   # Аппаратное ускорение виртуализации
  disk_size           = "31G"                   # Размер виртуального диска
  memory              = 4096                    # Объём оперативной памяти в МБ
  cpus                = 4                       # Количество виртуальных процессоров
  disk_interface      = "virtio"                # Интерфейс диска — протокол, через который ВМ видит диск
  net_device          = "virtio-net"            # Модель сетевого адаптера, эмулируемого QEMU
  communicator        = "none"                  # Без SSH/WinRM — управление только через boot_command
  shutdown_timeout    = "40m"                   # Максимальное время ожидания выключения ВМ
  headless            = true                    # Запуск без графического окна QEMU
  use_default_display = false                   # Не использовать дисплей по умолчанию (нужно для headless)
  vnc_port_min        = 5959                    # Минимальный порт VNC для подключения к консоли
  vnc_port_max        = 5959                    # Максимальный порт VNC (фиксируем один порт)
  vnc_bind_address    = "127.0.0.1"             # Адрес привязки VNC (только локально)

  # Второй CD-ROM с конфигурационным файлом OPNsense
  cd_content = {
    "conf/config.xml" = "config.xml" # config.xml из корня проекта → conf/config.xml на ISO
  }
  cd_label = "OPNSENSE_CONFIG" # Метка тома — по ней OPNsense находит диск с конфигом

  boot_wait = "2s"
  boot_command = [
    # Пропускаем таймаут загрузочного меню
    "<enter>",
    # Ждём полной загрузки Live CD
    "<wait60>",
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
    # Выбор носителя с конфигом: два раза вниз (sr1 — второй CD-ROM)
    "<down><down><enter>",
    "<wait2s>",
    # Подтверждаем успешный импорт конфигурации
    "<enter>",
    "<wait2s>",
    # Install (ZFS)
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
    # Ждём завершения установки
    "<wait5m>",
    # Финальный экран: выбираем Shell (второй пункт после Reboot)
    "<down><enter>",
    "<wait2>",
    # Отправляем OS команду выключения
    "<down><enter>",
  ]
}

build {
  sources = ["source.qemu.opnsense"]
}
