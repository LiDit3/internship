# Задание 2: Настройка SSH-сервера, управление пользователями и удалённый доступ

## Цель
Освоить базовое администрирование Linux: создание пользователей, безопасную настройку SSH/SFTP, интеграцию с Windows-инструментами для разработки и администрирования. Задокументировать процесс для портфолио.

## Стек и инструменты
- **ОС:** Linux (консольный режим, минимальная установка)
- **Сервис:** `OpenSSH Server`
- **Клиенты:** `PuTTY`, `Notepad++` + плагин `NppFTP`, `WinSCP`
- **Протоколы:** `SSH`, `SFTP`

## Чек-лист выполнения
- [x] Создан отдельный пользователь (например, `intern` или `devuser`)
- [x] Установлен и активирован SSH-сервер
- [x] В `/etc/ssh/sshd_config` установлено `PermitRootLogin no`
- [x] Сервис SSH перезапущен, статус `active (running)`
- [x] Подключение через `PuTTY` успешно (под новым пользователем)
- [x] `Notepad++` настроен с плагином `NppFTP` для SFTP
- [x] `WinSCP` подключается и позволяет просматривать/передавать файлы
- [x] Ключевые команды, конфиги и скриншоты задокументированы

## Краткая инструкция (Reference)
> Команды приведены для Debian/Ubuntu.

**1. Создание пользователя**
`````bash
sudo useradd -m -s /bin/bash intern
sudo passwd intern
# (Рекомендуется) Добавить в группу sudo/wheel для последующих задач
sudo usermod -aG sudo intern   # Debian/Ubuntu
`````
**2. Установка и запуск SSH**
`````bash
# Debian/Ubuntu
sudo apt update && sudo apt install -y openssh-server
sudo systemctl enable --now ssh
`````
**3. Запрет входа root**
`````bash
# Откройте конфиг редактором
sudo nano /etc/ssh/sshd_config
# Найдите строку PermitRootLogin и измените на:
PermitRootLogin no
# Сохраните и перезапустите сервис
sudo systemctl restart sshd
`````
> Проверка: `grep -E "^PermitRootLogin" /etc/ssh/sshd_config` → должно вывести `PermitRootLogin no`

**4. Фаервол и статус**
`````bash
sudo systemctl status sshd
sudo ufw allow ssh   # или sudo firewall-cmd --permanent --add-service=ssh && sudo firewall-cmd --reload
`````
**Проверка результата (Success Criteria)**
| Инструмент | Протокол | Действие | Ожидаемый результат | 
|---|------|---------|---------------------|
| PuTTY | SSH | Ввод IP, порт '`22`, логин `intern` | Консольная сессия, приглашение `intern@vm:~$` |
| Notepad++ (NppFTP) | SFTP | `Plugins → NppFTP → Show NppFTP Window → Profile Settings → Add New` | Файловая структура `~` видна в панели плагина, файлы открываются/сохраняются |
| WinSCP | SFTP |`Новый сайт → Протокол: SFTP, IP, порт 22, логин/пароль` | Окно файлового менеджера, drag & drop работает |

> **NppFTP:** Устанавливается через Plugins → Plugins Admin. При первом подключении появится предупреждение о неизвестном отпечатке хоста (SSH fingerprint) → нажмите `Accept`.

Отладка: При ошибках подключения смотрите логи в реальном времени:
`````
# Debian/Ubuntu
sudo tail -f /var/log/auth.log
# Или через systemd (универсально)
sudo journalctl -u sshd -f
`````
