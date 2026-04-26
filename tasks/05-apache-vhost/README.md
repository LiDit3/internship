# Задание 5: Развёртывание Apache2, настройка виртуального хоста и html страницы

## Цель
Освоить базовое администрирование веб-сервера Apache2: установка, проверка дефолтной конфигурации, создание виртуального хоста на кастомном порту, размещение статического контента (HTML + изображение). Сравнить подход Apache с ранее изученным nginx. Зафиксировать процесс в портфолио.

## Стек и инструменты
- **Гипервизор:** `Oracle VM VirtualBox` (или иная платформа)
- **ОС:** `Debian 13 (Trixie)` — консольный режим, минимальная установка
- **Веб-сервер:** `Apache2`
- **Инструменты:** `curl`, `nano`/`vim`, `a2ensite`/`a2enmod`, `scp`/`sftp` (опционально)
- **Сеть:** `NAT` с пробросом портов **или** `Bridged Adapter`

## Чек-лист выполнения
- [x] Создана и запущена ВМ с Debian (минимальная установка)
- [x] Система обновлена: `apt update && apt upgrade -y`
- [x] Установлен и активирован `apache2`
- [x] Проверен дефолтный сайт: `http://127.0.0.1` → Apache2 welcome page
- [x] Создан конфиг виртуального хоста на порту `8090`
- [x] Активирован сайт через `a2ensite`
- [x] Создана кастомная `index.html` с изображением
- [x] Проверен доступ: `http://127.0.0.1:8090` → отображается ваша страница
- [x] Настроены права доступа к файлам (владелец `www-data`)
- [x] Ключевые шаги, конфиги и скриншоты задокументированы

## Краткая инструкция (Reference)
> Все команды выполняются внутри ВМ с Debian. При использовании NAT в VirtualBox настройте проброс портов: `Host: 8090 → Guest: 8090`.

**1. Обновление и установка Apache2**
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y apache2
sudo systemctl enable --now apache2
```
**2. Проверка дефолтного сайта**
```bash
# Внутри ВМ
curl -I http://127.0.0.1
# Ожидаемый ответ: HTTP/1.1 200 OK

# С хост-машины (при правильном пробросе портов)
# Браузер: http://127.0.0.1 → должна открыться страница "Apache2 Debian Default Page"
```
**3. Создание виртуального хоста на порту 8090**
```bash
# Создайте конфиг
sudo nano /etc/apache2/sites-available/my-site-8090.conf
```
```apache
# /etc/apache2/sites-available/my-site-8090.conf
<VirtualHost *:8090>
    ServerName localhost
    ServerAdmin webmaster@localhost

    DocumentRoot /var/www/my-site-8090

    <Directory /var/www/my-site-8090>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Логирование
    ErrorLog ${APACHE_LOG_DIR}/my-site-8090-error.log
    CustomLog ${APACHE_LOG_DIR}/my-site-8090-access.log combined
</VirtualHost>
```
**4. Активация сайта и подготовка контента**
```bash
# Создайте директорию и файл
sudo mkdir -p /var/www/my-site-8090
sudo nano /var/www/my-site-8090/index.html
```
```html
<!-- /var/www/my-site-8090/index.html -->
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>Моё портфолио — Apache</title>
    <style>
        body { font-family: sans-serif; max-width: 800px; margin: 2rem auto; background: #f9f9f9; }
        .card { background: #fff; padding: 1.5rem; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        img { max-width: 100%; height: auto; border-radius: 8px; margin-top: 1rem; }
    </style>
</head>
<body>
    <div class="card">
        <h1>🚀 Привет! Это моя страница на Apache2</h1>
        <p>Задание #5 стажировки: виртуальный хост на порту 8090</p>
        <p><strong>Сервер:</strong> <code>Apache/2.4.x (Debian)</code></p>
        <img src="portfolio.jpg" alt="Моё фото">
    </div>
</body>
</html>
```
```bash
# Загрузите изображение (через scp/sftp или напрямую в ВМ)
# Установите корректные права
sudo chown -R www-data:www-data /var/www/my-site-8090
sudo chmod -R 755 /var/www/my-site-8090

# Активируйте сайт и перезагрузите Apache
sudo a2ensite my-site-8090.conf
sudo apache2ctl configtest    # Проверка синтаксиса
sudo systemctl reload apache2
```
**5. Настройка проброса портов в VirtualBox (если используется NAT)**
```
VirtualBox Manager → Ваша ВМ → Настройки → Сеть → Адаптер 1 → Дополнительно → Проброс портов:
| Имя   | Протокол | Адрес хоста | Порт хоста | Адрес гостя | Порт гостя |
|-------|----------|-------------|------------|-------------|------------|
| apache| TCP      | 127.0.0.1   | 8090       |             | 8090       |
```
**Проверка результата (Success Criteria)**
| Компонент   | Команда / Действие | Ожидаемый результат |
|-------|----------|-------------|
| Apache статус | `sudo systemctl status apache2` | `active (running)` |
| Дефолтный сайт | `curl -s http://127.0.0.1 \|\ grep -i "apache"` | Содержимое содержит "Apache2 Debian Default Page" |
| Конфиг валиден | `sudo apache2ctl configtest` | `active (running)` |
| Виртуальный хост | `curl -I http://127.0.0.1:8090` | `Syntax OK` |
| Контент | `curl -s http://127.0.0.1:8090 \|\ grep -i "портфолио"` | Кастомная страница с заголовком/текстом |
| Изображение | Браузер: `http://127.0.0.1:8090` | Страница отображается, картинка загружается без ошибок |

> Рекомендации
- **Модули Apache:** Для расширения функционала используйте `a2enmod`:
  ```bash
  sudo a2enmod rewrite    # Для .htaccess правил
  sudo a2enmod headers    # Для заголовков безопасности
  sudo a2enmod ssl        # Для HTTPS 
  ```
- **Безопасность:** Отключите индексацию директорий (`Options -Indexes`), как показано в конфиге. Для продакшена добавьте заголовки:
  ```apache
  <IfModule mod_headers.c>
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
  </IfModule>
  ```
- **Отладка:** При ошибках 403/404 смотрите логи:
  ```bash
  sudo tail -f /var/log/apache2/error.log
  sudo tail -f /var/log/apache2/my-site-8090-error.log
  ```
- **Права доступа:** Убедитесь, что www-data имеет права на чтение:
  ```bash
  sudo chown -R www-data:www-data /var/www/my-site-8090
  sudo chmod -R 755 /var/www/my-site-8090
  ```
  
