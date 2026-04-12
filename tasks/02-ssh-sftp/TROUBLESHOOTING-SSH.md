# TROUBLESHOOTING-SSH: Диагностика и решение проблем подключения

## Быстрая диагностика (чек-лист)
Выполняйте по порядку. Отмечайте `[x]` при успехе.

- [x] ВМ имеет корректный IP (`ip a` → не `127.0.0.1`, не `169.254.x.x`)
- [x] SSH-сервис активен: `systemctl status ssh` / `sshd`
- [x] Порт `22` слушается: `ss -tlnp | grep :22`
- [x] Фаервол гостя пропускает `22/tcp`: `sudo ufw status` / `firewall-cmd --list-all`
- [x] Пользователь существует и имеет пароль: `id <user>` / `sudo passwd <user>`
- [x] `PermitRootLogin no` применяется без синтаксических ошибок: `sudo sshd -T | grep permitrootlogin`

---

## Типовые ошибки и решения

### 1. `Connection refused`
**Симптом:** Клиент мгновенно возвращает `Connection refused` или `Unable to connect to remote host: Connection refused`

| Сторона | Диагностика | Решение |
|---------|-------------|---------|
| **Сервер** | `systemctl status ssh` (или `sshd`)<br>`ss -tlnp \| grep :22` | `sudo systemctl restart ssh`<br>Убедитесь, что `Port 22` не закомментирован в `/etc/ssh/sshd_config` |
| **Сеть** | `nmap -p 22 <VM_IP>` | Если порт `closed` → сервис не запущен или слушает другой порт.<br>Если `filtered` → фаервол блокирует |
| **VirtualBox** | Настройки ВМ → Сеть → Проброс портов | При `NAT`: добавьте правило `Host Port: 2222 → Guest Port: 22`<br>Клиент: `ssh -p 2222 user@127.0.0.1` |

---

### 2. `Connection timed out` / `Network is unreachable`
**Симптом:** Клиент висит 30-60 сек и завершается с таймаутом

| Причина | Диагностика | Решение |
|---------|-------------|---------|
| **Неверный IP** | `ping <VM_IP>` → `Destination Host Unreachable` | Проверьте тип адаптера в VirtualBox. Для простоты используйте `Bridged Adapter` или `NAT Network` |
| **Фаервол хоста/гостя** | `sudo ufw status` / Windows Defender Firewall | Временно: `sudo ufw allow 22/tcp`<br>Проверьте правила входящих соединений в Windows, если используете `Bridged` |
| **Маршрутизация** | `ip route` / `route print` | Убедитесь, что шлюз по умолчанию указывает на интерфейс с доступом в сеть |

---

### 3. `Permission denied (password,publickey)`
**Симптом:** Сервер отклоняет пароль или ключ, несмотря на их корректность

| Причина | Диагностика | Решение |
|---------|-------------|---------|
| **Root заблокирован** | Пытаетесь войти как `root` | Создайте/используйте обычного пользователя. `PermitRootLogin no` работает корректно. |
| **Пароль не установлен** | `sudo grep <user> /etc/shadow` → `!!` или `*` | `sudo passwd <user>` и задайте сложный пароль |
| **Auth методы отключены** | `sudo sshd -T \| grep -E "password\|pubkey"` | В `/etc/ssh/sshd_config`:<br>`PasswordAuthentication yes`<br>`PubkeyAuthentication yes`<br>`sudo systemctl restart ssh` |
| **SELinux / AppArmor** | `sudo dmesg \| grep -i ssh` или `audit.log` | `sudo setsebool -P sshd_full_access 1` (SELinux)<br>Или временно `setenforce 0` для теста |

> **Как смотреть логи в реальном времени:**  
> `sudo journalctl -u ssh -f` (Debian/Ubuntu)  

---

### 4. `Wrong MAC` / `Algorithm negotiation failed` / `Unable to use key type ssh-rsa`
**Симптом:** Современные OpenSSH-серверы отключают устаревшие алгоритмы. Старые клиенты (PuTTY <0.78, WinSCP <5.19) не могут подключиться.

| Сторона | Диагностика | Решение |
|---------|-------------|---------|
| **Клиент (рекомендуется)** | `ssh -v user@host` → `no matching key exchange method found` | Обновите PuTTY/WinSCP до последних версий. Поддерживают `ecdsa-sha2-nistp256`, `curve25519` |
| **Сервер (временный)** | `sudo sshd -T \| grep -E "kexalgorithms\|hostkeyalgorithms"` | В `/etc/ssh/sshd_config` добавьте:<br>`HostKeyAlgorithms +ssh-rsa,ssh-dss`<br>`PubkeyAcceptedAlgorithms +ssh-rsa`<br>⚠️ Только для тестов! Верните настройки после проверки. |
| **PuTTY/WinSCP** | Ошибка `Server refused our key` или `MAC error` | В настройках сессии: `Connection → SSH → Kex` → отметьте `Diffie-Hellman group 14-sha256`<br>В WinSCP: `Advanced → SSH → KEX` → выберите совместимый алгоритм |

---

### 5. `Too many authentication failures` / `MaxAuthTries reached`
**Симптом:** Клиент отправляет несколько ключей из `ssh-agent`, сервер разрывает соединение до запроса пароля.

| Действие | Команда / Настройка |
|----------|---------------------|
| **Отключить агент на время** | `ssh -o IdentitiesOnly=yes -o PubkeyAuthentication=no user@host` |
| **Очистить кэш ключей** | Windows: `ssh-agent -d` или `Remove-Item $env:USERPROFILE\.ssh\id_*`<br>Linux: `ssh-add -D` |
| **Увеличить лимит (сервер)** | `MaxAuthTries 6` в `sshd_config` (по умолчанию `6`, редко требуется менять) |

---

## Лог диагностики (заполняется по мере работы)

| # | Дата | Симптом | Выполненные команды | Гипотеза | Решение | Статус |
|---|------|---------|---------------------|----------|---------|--------|
| 1 | `YYYY-MM-DD` | `Connection refused` при подключении PuTTY | `systemctl status ssh`, `ss -tlnp` | Сервис не запущен после перезагрузки | `systemctl enable --now ssh` | ✅ Done |
| 2 | `...` | `Permission denied` для пользователя `intern` | `journalctl -u ssh -f`, `passwd intern` | Пустой хэш пароля | `sudo passwd intern` + повторный вход | ✅ Done |
| 3 | | | | | | |

---

## Финальная проверка (Success Criteria)
- [x] `sudo systemctl is-active ssh` → `active`
- [x] `sudo sshd -T \| grep permitrootlogin` → `permitrootlogin no`
- [x] PuTTY: вход под `<user>` успешен, сессия стабильна
- [x] WinSCP: протокол `SFTP`, файловая структура доступна, передача файлов работает
- [x] Notepad++ + NppFTP: подключение к `sftp://<user>@<ip>:22`, редактирование и сохранение файлов без ошибок
- [x] В логах сервера нет `error` или `fatal` за последний час
