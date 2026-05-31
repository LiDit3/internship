# Задание 6: Установка MariaDB (MySQL) + phpMyAdmin на Debian 13

> **Цель**: Развернуть СУБД, создать пользователя и базу данных, установить phpMyAdmin на Apache (порт 8080), проверить доступ извне и создать тестовую таблицу через веб-интерфейс.

---

## Структура решения

```
task-06-mariadb-phpmyadmin/
├── README.md                          # Этот файл
├── scripts/
│   ├── setup-mysql.sql                # SQL: создание БД и пользователя
│   ├── create-test-table.sql          # SQL: создание таблицы test
│   └── check-mariadb.sh               # Bash: проверка установки (опционально)
├── configs/
│   └── apache-phpmyadmin.conf         # Конфиг алиаса для phpMyAdmin
├── screenshots/
│   ├── 01-terminal-commands.png          # Терминал с выполнением команд
│   ├── 02-phpmyadmin-dashboard.png       # Панель управления
│   ├── 03-test-table-created.png         # Структура таблицы test
│   └── 04-phpmyadmin-login.png           # Окно входа
└── TROUBLESHOOTING.md                 # Частые проблемы и решения
```

---

## Исходные условия

| Компонент | Значение |
|-----------|----------|
| ОС | Debian 13 (Trixie), консольный режим |
| Веб-сервер | Apache2 на порту **8080** (уже настроен) |
| Параллельный сервис | Nginx на порту **8090** (не трогаем) |
| Доступ | Проброс портов в VirtualBox: `Host:8080 → Guest:8080` |

> **Важно**: В Debian 13 пакет `mysql-server` заменён на `mariadb-server` — полностью совместимый форк. Все команды и SQL-запросы идентичны.

---

## Пошаговая инструкция

### Шаг 1: Установка MariaDB

```bash
# Обновление репозиториев
sudo apt update

# Установка сервера и клиента
sudo apt install -y mariadb-server mariadb-client

# Проверка статуса
sudo systemctl status mariadb
# Ожидаем: ● active (running)

# Включение автозагрузки
sudo systemctl enable mariadb
```

---

### Шаг 2: Базовая настройка безопасности

```bash
# Запуск мастера безопасной настройки
sudo mariadb-secure-installation
```

Рекомендуемые ответы:
```
Switch to unix_socket authentication? → No
Change root password? → No (используем sudo)
Remove anonymous users? → Yes
Disallow root login remotely? → Yes
Remove test database? → Yes
Reload privilege tables? → Yes
```

---

### Шаг 3: Создание базы данных и пользователя

#### 🔹 Способ А: Интерактивно (через консоль СУБД)

```bash
# Вход в консоль MariaDB
sudo mysql
```

```sql
-- Внутри MariaDB [(none)]>

-- 1. Создаём базу с поддержкой UTF-8
CREATE DATABASE internship_db 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

-- 2. Создаём пользователя
CREATE USER 'intern_user'@'localhost' 
    IDENTIFIED BY 'StrongP@ssw0rd!2026';

-- 3. Выдаём права только на нашу базу
GRANT ALL PRIVILEGES ON internship_db.* TO 'intern_user'@'localhost';

-- 4. Применяем изменения
FLUSH PRIVILEGES;

-- 5. Проверка
SELECT User, Host FROM mysql.user WHERE User = 'intern_user';
SHOW DATABASES LIKE 'internship_db';

-- Выход
EXIT;
```

#### 🔹 Способ Б: Через SQL-файл (для автоматизации)

Файл `scripts/setup-mysql.sql`:
```sql
CREATE DATABASE IF NOT EXISTS internship_db 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'intern_user'@'localhost' 
    IDENTIFIED BY 'StrongP@ssw0rd!2026';

GRANT ALL PRIVILEGES ON internship_db.* TO 'intern_user'@'localhost';

FLUSH PRIVILEGES;

SELECT User, Host FROM mysql.user WHERE User = 'intern_user';
SHOW DATABASES LIKE 'internship_db';
```

Запуск:
```bash
sudo mysql < scripts/setup-mysql.sql
```

---

### Шаг 4: Проверка подключения пользователем

```bash
# Вход под новым пользователем
mysql -u intern_user -p -D internship_db
# Пароль: StrongP@ssw0rd!2026

# Внутри консоли:
SHOW TABLES;  -- должно быть пусто
EXIT;
```

---

### Шаг 5: Установка phpMyAdmin

```bash
# Установка с зависимостями
sudo apt install -y phpmyadmin php-mbstring php-zip php-gd php-json php-curl

# При настройке:
# 1. Web server to reconfigure? → [Пробел] apache2 → Enter
# 2. Configure database with dbconfig-common? → Yes
# 3. Пароль для phpmyadmin@localhost → запомните или оставьте автогенерацию
```

> Если мастер не появился: `sudo dpkg-reconfigure phpmyadmin`

---

### Шаг 6: Настройка доступа на порту 8080

#### Вариант: Символическая ссылка (проще)

```bash
# Создаём ссылку в DocumentRoot Apache
sudo ln -s /usr/share/phpmyadmin /var/www/my-site-8080/phpmyadmin

# Права доступа
sudo chown -R www-data:www-data /usr/share/phpmyadmin
sudo chmod -R 755 /usr/share/phpmyadmin

# Перезагрузка Apache
sudo systemctl reload apache2
```

#### Вариант: Отдельный конфиг (чище)

Файл `configs/apache-phpmyadmin.conf`:
```apache
Alias /phpmyadmin /usr/share/phpmyadmin

<Directory /usr/share/phpmyadmin>
    Options -Indexes +FollowSymLinks
    AllowOverride All
    Require all granted
    DirectoryIndex index.php index.html
</Directory>

<Directory /usr/share/phpmyadmin/setup>
    Require all denied
</Directory>
```

Активация:
```bash
sudo cp configs/apache-phpmyadmin.conf /etc/apache2/conf-available/phpmyadmin-8080.conf
sudo a2enconf phpmyadmin-8080
sudo systemctl reload apache2
```

---

### 7: Проверка доступа из хост-машины

1. Откройте браузер на хост-машине
2. Перейдите: `http://127.0.0.1:8080/phpmyadmin`
3. Должно открыться окно входа

**Данные для входа**:
| Поле | Значение |
|------|----------|
| Username | `intern_user` |
| Password | `StrongP@ssw0rd!2026` |
| Server | `localhost` |

---

### Шаг 8: Создание таблицы `test` через веб-интерфейс

1. После входа выберите базу `internship_db` в левой панели
2. Нажмите вкладку **"Создать таблицу"**
3. Заполните параметры:

| Поле | Тип | Длина | Атрибуты | Индекс | A_I |
|------|-----|-------|----------|--------|-----|
| `id` | INT | — | UNSIGNED, NOT NULL | PRIMARY | ✅ |
| `field1` | VARCHAR | 255 | COLLATE utf8mb4_unicode_ci | — | — |
| `field2` | TEXT | — | COLLATE utf8mb4_unicode_ci | — | — |

4. Нажмите **"Сохранить"**

✅ Таблица создана!

---

### Альтернатива: создание таблицы через SQL

Файл `scripts/create-test-table.sql`:
```sql
USE internship_db;

CREATE TABLE IF NOT EXISTS test (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    field1 VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    field2 TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    PRIMARY KEY (id),
    INDEX idx_field1 (field1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Проверка
DESCRIBE test;
```

Применение:
```bash
mysql -u intern_user -p -D internship_db < scripts/create-test-table.sql
```

---

## Безопасность: обязательные шаги

```apache
# 1. Ограничьте доступ к phpMyAdmin по IP (в продакшене)
<Directory /usr/share/phpmyadmin>
    Require ip 127.0.0.1
    Require ip 192.168.56.1  # IP хост-машины
</Directory>

# 2. Смените стандартный путь (защита от ботов)
Alias /pma /usr/share/phpmyadmin  # вместо /phpmyadmin

# 3. Настройте blowfish_secret в config.inc.php
$cfg['blowfish_secret'] = 'YOUR_32_CHAR_RANDOM_STRING_HERE!';

# 4. Отключите проверку версий
$cfg['VersionCheck'] = false;
```