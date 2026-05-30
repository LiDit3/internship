## Частые проблемы и решения

### 1. `open() "/etc/nginx/sites-enabled/..." failed (2: No such file or directory)`

**Причина**: Битая символическая ссылка или отсутствующий файл конфигурации.

**Решение**:
```bash
# Проверить ссылку
ls -la /etc/nginx/sites-enabled/

# Если ссылка битая — удалить и пересоздать с абсолютным путём
sudo rm /etc/nginx/sites-enabled/my-site-8090
sudo ln -s /etc/nginx/sites-available/my-site-8090 /etc/nginx/sites-enabled/

# Проверить и применить
sudo nginx -t && sudo systemctl reload nginx
```
### 1. Страница отображается с «кракозябрами»: `РџСЂРёРІРµС‚!...`
Причина: Файл сохранён в одной кодировке, а браузер интерпретирует в другой (чаще всего: UTF-8 байты как Windows-1251).

Диагностика:
```bash
# Проверить кодировку файла
file -i /var/www/my-site-8090/index.html
# Ожидаемо: charset=utf-8

# Проверить заголовки ответа сервера
curl -I http://127.0.0.1:8090 | grep -i content-type
```
**Решение**:
1. Сохранить файл как UTF-8 без BOM:
- В `nano`: просто сохранить (по умолчанию UTF-8)
- Конвертация: `iconv -f windows-1251 -t utf-8 input.html -o output.html`
2. Добавить в HTML (уже есть в шаблоне):
```html
server {
    charset utf-8;
    add_header Content-Type "text/html; charset=utf-8" always;
    # ...остальные директивы
}
```
4. Перезагрузить и очистить кэш браузера:
```bash
sudo nginx -t && sudo systemctl reload nginx
# В браузере: Ctrl+Shift+R
```
### 4. Страница не загружается (404 / 403 / соединение сброшено)

| Ошибка | Возможная причина | Решение |
|------|------|---------|
| `404 Not Found` | Неправильный `root` или файл не в той папке | Проверить `root /var/www/my-site-8090` и наличие `index.html` | 
| `403 Forbidden` | Нет прав на чтение файла | `sudo chmod 644 /var/www/my-site-8090/index.html` | 
| `Connection refused` | nginx не слушает порт 8090 | Проверить `listen 8090;` в конфиге и `sudo ss -tlnp | grep 8090` |
| Картинка не грузится | Неправильный путь или права | Убедиться, что `portfolio.jpg` лежит в `/var/www/my-site-8090/` и имеет права `644` |

### 4. nginx: [emerg] bind() to 0.0.0.0:8090 failed (98: Address already in use)

Причина: Порт 8090 уже занят другим процессом.
**Решение**:
```bash
# Найти, кто использует порт
sudo ss -tlnp | grep 8090
# или
sudo lsof -i :8090

# Варианты:
# 1. Остановить конфликтующий сервис
sudo systemctl stop <service-name>

# 2. Или выбрать другой порт в конфиге
listen 8091;
```

### 5. Изменения в конфиге не применяются
Причина: Забыли перезагрузить nginx или ошибка в синтаксисе.
**Решение**:
```bash
# Всегда проверяйте перед перезагрузкой!
sudo nginx -t

# Если ок — применяйте
sudo systemctl reload nginx  # мягкая перезагрузка (без разрыва соединений)
# или
sudo systemctl restart nginx # полная перезагрузка
```

### Полезные команды
```bash
# Проверка конфигурации
sudo nginx -t

# Статус nginx
sudo systemctl status nginx

# Просмотр логов в реальном времени
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Проверка, на каких портах слушает nginx
sudo ss -tlnp | grep nginx

# Проверка ответа сервера
curl -v http://127.0.0.1:8090

# Проверка кодировки файла
file -i /var/www/my-site-8090/index.html

# Пересоздание символической ссылки
sudo rm /etc/nginx/sites-enabled/my-site-8090
sudo ln -s /etc/nginx/sites-available/my-site-8090 /etc/nginx/sites-enabled/
```
