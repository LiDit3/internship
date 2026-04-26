# TROUBLESHOOTING: Диагностика сетевых проблем в ВМ

## Быстрая диагностика (чек-лист)
Выполняйте по порядку. Отмечайте `[x]` при успехе.

- [ ] Гипервизор: тип адаптера установлен в `NAT` (или `Сетевой мост`)
- [ ] ВМ: интерфейс в состоянии `UP` (`ip a` / `ipconfig`)
- [ ] IP получен: не `169.254.x.x` / `0.0.0.0`
- [ ] Шлюз отвечает: `ping <gateway_ip>`
- [ ] Внешний IP отвечает: `ping 8.8.8.8` или `1.1.1.1`
- [ ] DNS резолвит: `nslookup ya.ru` или `ping ya.ru`
- [ ] Прокси не требуется / настроен корректно

---

## Типовые ошибки и решения

### 1. Нет сети / `Network is unreachable`
**Симптом:** Интерфейс `DOWN`, нет IP, `ping` не проходит даже до шлюза.

| ОС / Среда | Диагностика | Решение |
|------------|-------------|---------|
| **VirtualBox** | Проверьте `Настройки → Сеть → Включить сетевой адаптер` | Переключите тип с `Не подключен` → `NAT`. При необходимости нажмите `Дополнительно → Сбросить MAC-адрес` |
| **Linux** | `ip a` → интерфейс без IP или `state DOWN` | `sudo ip link set dev <iface> up`<br>`sudo systemctl restart NetworkManager` или `sudo dhclient <iface>` |
| **Windows** | `ipconfig` → `Media disconnected` или `169.254.x.x` | `netsh interface set interface name="<Имя>" admin=enable`<br>`ipconfig /release` → `ipconfig /renew` |

**Проверка:** `ping 192.168.0.1` (или ваш шлюз) → `64 bytes from ...`

---

### 2. Ошибка DNS: IP пингуется, домен — нет
**Симптом:** `ping 8.8.8.8` ✅, `ping ya.ru` ❌ `Name or service not known`

| ОС | Диагностика | Решение |
|----|-------------|---------|
| **Linux** | `cat /etc/resolv.conf` → пусто или `nameserver 127.0.0.53` | Временный тест: `echo "nameserver 8.8.8.8" \| sudo tee /etc/resolv.conf`<br>Постоянно: настройте `systemd-resolved` или `/etc/netplan/*.yaml` |
| **Windows** | `ipconfig /all` → DNS-серверы отсутствуют или некорректны | Панель управления → Сетевые подключения → Свойства IPv4 → DNS: `8.8.8.8`, `1.1.1.1` |

**Проверка:** `curl -I ya.ru` → `HTTP/2 200` или `301`

---

### 3. Требуется прокси (корпоративная сеть / учебная лаборатория)
**Симптом:** Браузер запрашивает авторизацию, `curl` возвращает `HTTP 407 Proxy Authentication Required`

| Компонент | Настройка |
|-----------|-----------|
| **Linux (системные переменные)** | `export HTTP_PROXY="http://user:pass@proxy:port"`<br>`export HTTPS_PROXY="http://user:pass@proxy:port"`<br>`export NO_PROXY="localhost,127.0.0.1,.local"` |
| **Linux (apt/dnf)** | `/etc/apt/apt.conf.d/proxy.conf`: `Acquire::http::Proxy "http://user:pass@proxy:port";` |
| **Linux (curl/wget)** | `curl -x http://proxy:port ya.ru`<br>`wget -e use_proxy=yes -e http_proxy=http://proxy:port ya.ru` |
| **Windows** | Параметры → Сеть и Интернет → Прокси → Включить вручную<br>`netsh winhttp set proxy proxy-server="http://proxy:port" bypass-list="localhost"` |

**Проверка:** `curl -v ya.ru` → в выводе `Connected to proxy (...) port ...` и `HTTP 200`

---

### 4. Конфликт IP / DHCP не отвечает
**Симптом:** Адрес `169.254.x.x` (APIPA), `dhclient` висит, VirtualBox DHCP сервер неактивен

| Действие | Команда / Настройка |
|----------|---------------------|
| Сброс сетевого стека VirtualBox | `File → Tools → Network Manager → NAT Networks` → создать/включить сеть |
| Ручной IP (Linux) | `sudo ip addr add 10.0.2.15/24 dev eth0`<br>`sudo ip route add default via 10.0.2.2` |
| Ручной IP (Windows) | `netsh interface ip set address name="Ethernet" static 10.0.2.15 255.255.255.0 10.0.2.2` |

**Проверка:** `ip route` / `route print` → шлюз `default` или `0.0.0.0` указывает на корректный интерфейс.

---

### 5. Блокировка фаерволом / антивирусом
**Симптом:** Пинг проходит, но `curl`/браузер таймаутит на `TCP connect`

| ОС | Диагностика | Решение |
|----|-------------|---------|
| **Linux** | `sudo ufw status` или `sudo iptables -L` | `sudo ufw disable` (только для тестирования!)<br>или `sudo iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT` |
| **Windows** | `Get-NetFirewallProfile \| Select Name, Enabled` | Временно отключить: `Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False`<br>Или создать правило: `New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Outbound -Protocol TCP -LocalPort Any -RemotePort 80,443 -Action Allow` |

> **Важно:** После проверки обязательно верните защиту в активное состояние.

---

### 4. Минимальная установка Debian / не установлены пакеты  apt 
**Симптом:** Команда  `curl` не доступна, `apt-get install curl` выдает ошибку `Media changed: please insert the disk labeled 'Debian GNU/Linux 7.4.0 _Wheezy_ - Official amd64 DVD Binary-1 20140208-13:47' in the drive and press Enter`

В подкаталоге настроек менеджера пакетов apt (по умолчанию `/etc/apt/sources.list.d`) создадим файл с расширением `sources`, например, с именем `debian.sources` и внесём в этот файл записи о зеркале репозиториев Debian Trixie.

`# nano /etc/apt/sources.list.d/debian.sources`

```debian.sources
Types: deb
URIs: https://deb.debian.org/debian
Suites: trixie trixie-updates
Components: main non-free-firmware contrib non-free
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
```
>Обратите внимание на то, что записи о репозиториях, указанные в созданном нами файле, не должны конфликтовать с записями в других файлах `*.sources` или `*.list` (например в стандартном файле `/etc/apt/sources.list`)

После этого выполняем обновление кэша менеджера пакетов: 
`# apt update`
Теперь можно будет устанавливать пакеты из подключённых репозиториев. 

---

## ✅ Финальная проверка (Success Criteria)
- [ ] Windows: браузер открывает `https://ya.ru` без ошибок сертификата/прокси
- [ ] Linux: `curl -sI ya.ru \| head -n 1` → `HTTP/2 200`
- [ ] Фаервол/защита возвращены в рабочее состояние
