# Задание 4: Развёртывание nginx, настройка виртуального хоста и кастомной страницы

## Цель
Освоить базовое администрирование веб-сервера: установка nginx, проверка дефолтной конфигурации, создание виртуального хоста на кастомном порту, размещение статического контента (HTML + изображение). Зафиксировать процесс настройки и тестирования в портфолио.

## Стек и инструменты
- **Гипервизор:** `Oracle VM VirtualBox`
- **ОС:** `Debian 13 (Bookworm)` — консольный режим, минимальная установка
- **Веб-сервер:** `nginx`
- **Инструменты:** `curl`, `nano`/`vim`, `scp`/`sftp` (опционально)
- **Сеть:** `NAT` с пробросом портов **или** `Bridged Adapter`

## Чек-лист выполнения
- [x] Создана и запущена ВМ с Debian (минимальная установка)
- [x] Система обновлена: `apt update && apt upgrade -y`
- [x] Установлен и активирован `nginx`
- [x] Проверен дефолтный сайт: `http://127.0.0.1` → nginx welcome page
- [x] Создан конфиг виртуального хоста на порту `8090`
- [x] Создана кастомная `index.html` с изображением
- [x] Проверен доступ: `http://127.0.0.1:8090` → отображается ваша страница
- [x] Настроены права доступа к файлам (если требуется)
- [x] Ключевые шаги, конфиги и скриншоты задокументированы

## Краткая инструкция (Reference)
> Все команды выполняются внутри ВМ с Debian. При использовании NAT в VirtualBox настройте проброс портов: `Host: 8090 → Guest: 8090`.

**1. Обновление и установка nginx**
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx
sudo systemctl enable --now nginx
```
**2. Проверка дефолтного сайта**
```bash
# Внутри ВМ
curl -I http://127.0.0.1
# Ожидаемый ответ: HTTP/1.1 200 OK

# С хост-машины (при правильном пробросе портов)
# Браузер: http://127.0.0.1 → должна открыться страница "Welcome to nginx!"
```
**3. Создание виртуального хоста на порту 8090**
```bash
# Создайте конфиг
sudo nano /etc/nginx/sites-available/my-site-8090
```
```nginx
# /etc/nginx/sites-available/my-site-8090
server {
    listen 8090;
    listen [::]:8090;

    root /var/www/my-site-8090;
    index index.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    # Разрешить отображение изображений
    location ~* \.(jpg|jpeg|png|gif|ico|svg)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
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
    <title>Моё портфолио</title>
    <style>
        body { font-family: sans-serif; max-width: 800px; margin: 2rem auto; }
        img { max-width: 100%; height: auto; border-radius: 8px; }
    </style>
</head>
<body>
    <h1>Привет! Это моя первая веб-страница на nginx</h1>
    <p>Задание #4 стажировки: виртуальный хост на порту 8090</p>
    <img src="portfolio.jpg" alt="Моё фото">
</body>
</html>
```
```bash
# Загрузите изображение (через scp/sftp или напрямую в ВМ)
# Пример: скопируйте файл в директорию сайта
sudo chmod 644 /var/www/my-site-8090/*

# Создайте симлинк для активации сайта
sudo ln -s /etc/nginx/sites-available/my-site-8090 /etc/nginx/sites-enabled/

# Проверьте синтаксис и перезагрузите nginx
sudo nginx -t
sudo systemctl reload nginx
```
**5. Настройка проброса портов в VirtualBox (если используется NAT)**
```
VirtualBox Manager → Ваша ВМ → Настройки → Сеть → Адаптер 1 → Дополнительно → Проброс портов:
| Имя  | Протокол | Адрес хоста | Порт хоста | Адрес гостя | Порт гостя |
|------|----------|-------------|------------|-------------|------------|
| nginx| TCP      | 127.0.0.1   | 8090       |             | 8090       |
```

**Проверка результата (Success Criteria)**
| Компонент  | Команда / Действие | Ожидаемый результат |
|------|----------|-------------|
| nginx статус | `sudo systemctl status nginx` | `active (running)` | 
| Дефолтный сайт | `curl -s http://127.0.0.1 \|\ grep -i "welcome"` | Содержимое страницы содержит "Welcome to nginx" | 
| Конфиг валиден | `sudo nginx -t` | `syntax is ok`, `test is successful`| 
| Виртуальный хост | `curl -I http://127.0.0.1:8090` | `HTTP/1.1 200 OK`| 
| Контент | `curl -s http://127.0.0.1:8090 \|\ grep -i "портфолио"` | `Кастомная страница с заголовком/текстом`| 
| Изображение | Браузер: `[sudo systemctl status nginx](http://127.0.0.1:8090)` | Страница отображается, картинка загружается без ошибок| 

**Рекомендации** 
- **Права доступа:** Убедитесь, что пользователь `www-data` имеет права на чтение файлов в `/var/www/my-site-8090/`: `sudo chown -R www-data:www-data /var/www/my-site-8090 && sudo chmod -R 755 /var/www/my-site-8090`
- **Отладка:** При ошибках 403/404 смотрите логи:
  ```bash
  sudo tail -f /var/log/nginx/error.log
  sudo tail -f /var/log/nginx/access.log
  ```
- Доступ с хоста: Если используете `Bridged Adapter`, узнайте IP ВМ через `ip a` и обращайтесь по `http://<VM_IP>:8090`. При NAT — только через проброс портов на `127.0.0.1`.
