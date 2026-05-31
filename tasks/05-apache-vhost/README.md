# Задание 5: Развёртывание Apache2, настройка виртуального хоста и html страницы

## Цель
Освоить базовое администрирование веб-сервера Apache2: установка, проверка дефолтной конфигурации, создание виртуального хоста на кастомном порту, размещение статического контента (HTML + изображение). Apache2 будет биндится к порту 8080, т.к. 8090 уже занят Nginx. Сравнить подход Apache с ранее изученным nginx. Зафиксировать процесс в портфолио.

Настроить одновременную работу **Apache2** и **Nginx** на одном сервере Debian:
- **Nginx** продолжает обслуживать сайт на порту **8090**
- **Apache2** настраивается на порт **8080**
- Разместить статическую страницу на Apache2 с изображением
- Сравнить подходы к конфигурации двух веб-серверов


## Стек и инструменты
- **Гипервизор:** `Oracle VM VirtualBox` (или иная платформа)
- **ОС:** `Debian 13 (Trixie)` — консольный режим, минимальная установка
- **Веб-сервер:** `Apache2`
- **Инструменты:** `curl`, `nano`/`vim`, `a2ensite`/`a2enmod`, `scp`/`sftp` (опционально)
- **Сеть:** `NAT` с пробросом портов **или** `Bridged Adapter`

## Чек-лист выполнения
- [x] Создана и запущена ВМ с Debian (минимальная установка)
- [x] Система обновлена: `apt update && apt upgrade -y`
- [x] Проверено, что **Nginx работает на порту 8090**
- [x] Установлен и активирован `apache2`
- [x] Apache2 настроен на прослушивание порта **8080**
- [x] Создан и активирован виртуальный хост Apache на порту 8080
- [x] Создана кастомная `index.html` с изображением
- [x] Проверен доступ: `http://127.0.0.1:8080` → страница Apache
- [x] Проверен доступ: `http://127.0.0.1:8090` → страница Nginx (без изменений)
- [x] Настроены права доступа к файлам (владелец `www-data`)
- [x] Конфликты портов исключены, оба сервиса в статусе `active (running)`


## 🔧 Пошаговая инструкция

### 0. Предварительная проверка: что уже работает
```bash
# Проверяем, что Nginx слушает порт 8090
sudo ss -tlnp | grep :8090
# Ожидаемый вывод: ... nginx ...

# Проверяем, что порт 8080 свободен
sudo ss -tlnp | grep :8080
# Если вывод пустой — порт свободен, можно продолжать
```

### 1. Установка Apache2
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y apache2
sudo systemctl enable --now apache2
```

### 2. Настройка Apache2 на порт 8080
По умолчанию Apache слушает порт 80. Нужно добавить прослушивание 8080.

```bash
# Добавляем Listen 8080 в конфигурацию портов
echo "Listen 8080" | sudo tee -a /etc/apache2/ports.conf

# Проверяем, что в файле появилась строка:
grep "Listen" /etc/apache2/ports.conf
# Должно быть: Listen 80, Listen 8080
```

### 3. Создание виртуального хоста на порту 8080
```bash
sudo nano /etc/apache2/sites-available/my-site-8080.conf
```

```apache
# /etc/apache2/sites-available/my-site-8080.conf
<VirtualHost *:8080>
    ServerName localhost
    ServerAdmin webmaster@localhost

    DocumentRoot /var/www/my-site-8080

    <Directory /var/www/my-site-8080>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Логирование (отдельные логи для удобства отладки)
    ErrorLog ${APACHE_LOG_DIR}/my-site-8080-error.log
    CustomLog ${APACHE_LOG_DIR}/my-site-8080-access.log combined
</VirtualHost>
```

### 4. Подготовка контента и активация сайта
```bash
# Создаём директорию и индекс-файл
sudo mkdir -p /var/www/my-site-8080
sudo nano /var/www/my-site-8080/index.html
```

```html
<!-- /var/www/my-site-8080/index.html -->
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>Моё портфолио — Apache2</title>
    <style>
        body { font-family: sans-serif; max-width: 800px; margin: 2rem auto; background: #f9f9f9; }
        .card { background: #fff; padding: 1.5rem; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        img { max-width: 100%; height: auto; border-radius: 8px; margin-top: 1rem; }
    </style>
</head>
<body>
    <div class="card">
        <h1>🚀 Привет! Это моя страница на Apache2</h1>
        <p>Задание #5: виртуальный хост на порту <strong>8080</strong></p>
        <p><strong>Сервер:</strong> <code>Apache/2.4.x (Debian)</code></p>
        <p><strong>Nginx работает параллельно на порту 8090</strong></p>
        <img src="portfolio.jpg" alt="Моё фото">
    </div>
</body>
</html>
```

```bash
# Загружаем изображение (если есть) в ту же директорию
# Например, через scp с хост-машины:
# scp portfolio.jpg user@vm-ip:/tmp/
# sudo mv /tmp/portfolio.jpg /var/www/my-site-8080/

# Устанавливаем корректные права
sudo chown -R www-data:www-data /var/www/my-site-8080
sudo chmod -R 755 /var/www/my-site-8080

# Активируем сайт и проверяем конфигурацию
sudo a2ensite my-site-8080.conf
sudo apache2ctl configtest    # Ожидаем: Syntax OK
sudo systemctl reload apache2
```

### 5. Настройка проброса портов в VirtualBox (NAT)
```
VirtualBox Manager → Ваша ВМ → Настройки → Сеть → Адаптер 1 → Проброс портов:

| Имя     | Протокол | Адрес хоста | Порт хоста | Адрес гостя | Порт гостя |
|---------|----------|-------------|------------|-------------|------------|
| nginx   | TCP      | 127.0.0.1   | 8090       |             | 8090       |
| apache  | TCP      | 127.0.0.1   | 8080       |             | 8080       |
```

> 💡 После изменения настроек сети в VirtualBox может потребоваться перезагрузка ВМ.

---

## ✅ Проверка результата

| Компонент | Команда / Действие | Ожидаемый результат |
|-----------|-------------------|-------------------|
| **Статус Apache** | `sudo systemctl status apache2` | `active (running)` |
| **Статус Nginx** | `sudo systemctl status nginx` | `active (running)` |
| **Порты** | `sudo ss -tlnp \| grep -E ':(8080\|8090)'` | Оба порта слушаются разными процессами |
| **Конфиг Apache** | `sudo apache2ctl configtest` | `Syntax OK` |
| **Apache контент** | `curl -s http://127.0.0.1:8080 \| grep -i "apache2"` | Содержит заголовок страницы |
| **Nginx контент** | `curl -s http://127.0.0.1:8090 \| grep -i "nginx"` | Страница Nginx без изменений |
| **Изображение** | Браузер: `http://127.0.0.1:8080` | Страница загружается, картинка отображается |

---

## 🔍 Отладка и полезные команды

```bash
# Если Apache не запускается — проверяем, не занят ли порт 8080
sudo ss -tlnp | grep :8080

# Если ошибка 403 — проверяем права на директорию
ls -la /var/www/ | grep my-site-8080

# Логи Apache для отладки
sudo tail -f /var/log/apache2/my-site-8080-error.log

# Логи Nginx (если вдруг что-то пошло не там)
sudo tail -f /var/log/nginx/error.log

# Перезагрузка только Apache (без влияния на Nginx)
sudo systemctl reload apache2

# Перезагрузка только Nginx
sudo systemctl reload nginx
```

---

## 📌 Рекомендации по безопасности и оптимизации

### Для Apache2:
```bash
# Включить полезные модули (по необходимости)
sudo a2enmod rewrite headers ssl

# Добавить заголовки безопасности в виртуальный хост:
<IfModule mod_headers.c>
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
</IfModule>
```

### Для сосуществования с Nginx:
- Убедитесь, что в конфигурации Nginx **нет** директивы `listen 8080;`
- Если в будущем потребуется проксирование, Nginx может выступать как reverse proxy для Apache:
  ```nginx
  # Пример: Nginx на 8090 проксирует запросы /apache/ на Apache:8080
  location /apache/ {
      proxy_pass http://127.0.0.1:8080/;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
  }
  ```

---

## 🧠 Сравнение Apache2 и Nginx (для портфолио)

| Критерий | Apache2 | Nginx |
|----------|---------|-------|
| Модель обработки | Процессы/потоки (MPM) | Событийно-ориентированная |
| Конфигурация | Файлы в `sites-available/`, `a2ensite` | Файлы в `sites-available/`, `ln -s` + `nginx -s reload` |
| Динамическая загрузка модулей | Через `a2enmod` | Компиляция или пакеты `libnginx-mod-*` |
| .htaccess поддержка | ✅ Да (по умолчанию) | ❌ Нет (требует переписывания правил) |
| Работа с статикой | Хорошо | Отлично (меньше памяти, выше скорость) |
| Reverse proxy | ✅ Через mod_proxy | ✅ Нативно, очень эффективно |

> 💡 Вывод для портфолио: **Nginx** идеален как фронтенд-прокси и для раздачи статики, **Apache2** — гибок для .htaccess и модульной архитектуры. Их совместное использование позволяет комбинировать преимущества.

