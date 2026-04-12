# Задание 6: Развёртывание MySQL, создание БД и настройка phpMyAdmin

## Цель
Освоить базовое администрирование СУБД: установка MySQL Server, создание пользователей и баз данных, настройка веб-интерфейса phpMyAdmin для управления БД. Научиться безопасно предоставлять доступ к панели управления и выполнять базовые операции через визуальный интерфейс. Зафиксировать процесс в портфолио.

## Стек и инструменты
- **Гипервизор:** `Oracle VM VirtualBox`
- **ОС:** `Debian 13 (Trixie)` — консольный режим, минимальная установка
- **СУБД:** `MySQL Server 8.0`
- **Веб-интерфейс:** `phpMyAdmin` + `Apache2` **или** `nginx` + `php-fpm`
- **Инструменты:** `mysql` CLI, `curl`, `nano`/`vim`, `scp`/`sftp`
- **Сеть:** `NAT` с пробросом портов **или** `Bridged Adapter`

## Чек-лист выполнения
- [x] Создана и запущена ВМ с Debian (минимальная установка)
- [x] Система обновлена: `apt update && apt upgrade -y`
- [x] Установлен и защищён `mysql-server` (`mysql_secure_installation`)
- [x] Создан пользователь БД и база данных (например, `intern` / `intern_db`)
- [x] Установлен и настроен веб-сервер (Apache2 или nginx) + PHP
- [x] Установлен и сконфигурирован `phpMyAdmin`
- [x] Проверен доступ с хоста: `http://<VM_IP>/phpmyadmin` → окно входа
- [x] Выполнен вход под созданным пользователем
- [x] Через интерфейс phpMyAdmin создана таблица `test` с полями:
  - `id` — `INT`, `PRIMARY KEY`, `AUTO_INCREMENT`
  - `field1` — `TEXT`
  - `field2` — `TEXT`

## Краткая инструкция (Reference)
> Все команды выполняются внутри ВМ с Debian. При использовании NAT настройте проброс портов: `Host: 8080 → Guest: 80` (для веб-интерфейса).

**1. Обновление и установка MySQL**
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y mysql-server
sudo mysql_secure_installation
```
> При запуске mysql_secure_installation:
> * Установите `VALIDATE PASSWORD COMPONENT` (опционально, для обучения можно `No`)
> * Задайте пароль для `root`
> * Удалите анонимных пользователей: `Yes`
> * Запретите удалённый вход root: `Yes`
> * Удалите тестовую БД: `Yes`
> * Перезагрузите привилегии: `Yes`

**2. Создание пользователя и базы данных**
```bash
# Вход в MySQL под root
sudo mysql -u root -p

# Внутри MySQL CLI:
CREATE DATABASE intern_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'intern'@'localhost' IDENTIFIED BY 'StrongP@ssw0rd!';
GRANT ALL PRIVILEGES ON intern_db.* TO 'intern'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

**3. Установка веб-сервера и PHP**
Вариант A: Apache2 (проще для новичков)
```bash
sudo apt install -y apache2 libapache2-mod-php php-mysql php-mbstring php-zip php-gd php-json php-curl
sudo systemctl enable --now apache2
```
Вариант B: nginx + php-fpm (более производственный)
```bash
sudo apt install -y nginx php-fpm php-mysql php-mbstring php-zip php-gd php-json php-curl
sudo systemctl enable --now nginx php8.2-fpm  # версия php может отличаться
```

**4. Установка phpMyAdmin**
```bash
sudo apt install -y phpmyadmin
```
> При установке:
> * Web server to reconfigure: выберите `apache2` (или `none`, если используете nginx)
> * Configure database for phpMyAdmin with dbconfig-common? → `Yes`
> * Задайте пароль для пользователя `phpmyadmin` в БД

Дополнительная настройка для Apache:
```bash
# Если не настроилось автоматически:
sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
sudo a2enconf phpmyadmin
sudo systemctl reload apache2
```
Настройка для nginx (если выбрали этот вариант):
```bash
# /etc/nginx/sites-available/phpmyadmin
server {
    listen 80;
    server_name _;
    root /usr/share/phpmyadmin;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock; # адаптируйте под версию
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Защита системных директорий
    location ~ /\. { deny all; }
    location ~* \.(sql|bak|log)$ { deny all; }
}
```
```bash
sudo ln -s /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

**5. Проброс портов в VirtualBox (если NAT)**
```
VirtualBox Manager → ВМ → Настройки → Сеть → Адаптер 1 → Проброс портов:
| Имя      | Протокол | Адрес хоста | Порт хоста | Адрес гостя | Порт гостя |
|----------|----------|-------------|------------|-------------|------------|
| phpmyadmin| TCP     | 127.0.0.1   | 8080       |             | 80         |
```
> Доступ с хоста: `http://127.0.0.1:8080/phpmyadmin`

**6. Проверка и создание таблицы через интерфейс**
1. Откройте в браузере: `http://<VM_IP>:8080/phpmyadmin` (или `http://127.0.0.1:8080/phpmyadmin`)
2. Войдите под пользователем `intern` / `StrongP@ssw0rd!`
3. Выберите базу `intern_db`
4. Нажмите «Создать таблицу» → имя: `test`, поля: `3`
5. Настройте поля:
   | Имя поля | Тип | Длина/Значения | Индекс |  |
   |----------|----------|-------------|------------|-------------|
   | `id` | `INT` | — | `PRIMARY` | [x] | 
   | `field1` | `TEXT` | — | — | [ ] | 
   | `field2` | `TEXT` | — | — | [ ] |
6. Нажмите «Сохранить» → таблица создана.

**Проверка результата (Success Criteria)**
| Компонент | Команда / Действие | Ожидаемый результат |
|----------|----------|-------------|
| MySQL статус | `sudo systemctl status mysql` | `active (running)` | 
| Пользователь БД | `mysql -u intern -p -e "SELECT USER();"` | `intern@localhost` | 
| Веб-сервер | `curl -I http://127.0.0.1/phpmyadmin` | `HTTP/1.1 200 OK` | 
| Доступ с хоста | Браузер: `http://<VM_IP>:8080/phpmyadmin`| Отображается окно входа phpMyAdmin | 
| Вход в phpMyAdmin | Логин: `intern`, пароль: `***` | Успешная авторизация, видна БД `intern_db` | 
| Таблица `test` | Интерфейс → вкладка «Структура» | Отображаются поля: `id`, `field1`, `field2` с корректными типами | 

### Рекомендации
* Безопасность phpMyAdmin:
```apache
# Apache: /etc/apache2/conf-available/phpmyadmin.conf
<Directory /usr/share/phpmyadmin>
    Require ip 192.168.56.1  # IP хоста в Bridged/NAT Network
    Require ip 127.0.0.1
</Directory>
```
  * Используйте `.htaccess` с базовой аутентификацией (`htpasswd`)
  * Рассмотрите доступ через SSH-туннель вместо прямого проброса порта
* **MySQL vs MariaDB:** В репозиториях Debian по умолчанию может предлагаться `mariadb-server`. Он полностью совместим с MySQL для учебных задач. Команды идентичны.
* Бэкап БД:
```bash
# Экспорт
mysqldump -u intern -p intern_db > backup_$(date +%F).sql
# Импорт
mysql -u intern -p intern_db < backup_2024-01-15.sql
```
* **Тестовые данные:** Добавьте через интерфейс 1-2 записи в таблицу `test`, чтобы продемонстрировать полный цикл: создание → вставка → просмотр.

**SQL-скрипт для автоматизации (опционально)**
```sql
-- sql/setup-db.sql
-- Создаёт БД, пользователя и таблицу для задания #6

CREATE DATABASE IF NOT EXISTS intern_db 
  CHARACTER SET utf8mb4 
  COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'intern'@'localhost' 
  IDENTIFIED BY 'StrongP@ssw0rd!';

GRANT ALL PRIVILEGES ON intern_db.* TO 'intern'@'localhost';
FLUSH PRIVILEGES;

USE intern_db;

CREATE TABLE IF NOT EXISTS test (
    id INT AUTO_INCREMENT PRIMARY KEY,
    field1 TEXT,
    field2 TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```
> Запуск: `sudo mysql -u root -p < sql/setup-db.sql`
