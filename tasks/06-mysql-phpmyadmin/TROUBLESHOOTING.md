## Отладка: частые проблемы

| Проблема | Решение |
|----------|---------|
| ❌ `Access denied` при входе | Проверьте пароль; убедитесь, что пользователь создан для `@'localhost'` |
| ❌ `404 Not Found` на `/phpmyadmin` | Проверьте: `ls -la /var/www/my-site-8080/phpmyadmin`; перезагрузите Apache |
| ❌ `500 Internal Server Error` | Установите `php-mbstring`: `sudo apt install php-mbstring`; проверьте логи |
| ❌ Видно исходный код `<?php` | Установите `libapache2-mod-php`: `sudo apt install libapache2-mod-php`; `sudo a2enmod php8.2` |
| ❌ Не отображается кириллица | Убедитесь, что БД и таблицы используют `utf8mb4_unicode_ci` |

### Полезные команды диагностики
```bash
# Проверка портов
sudo ss -tlnp | grep -E ':(8080|3306)'

# Проверка пользователей
sudo mysql -e "SELECT User, Host, plugin FROM mysql.user;"

# Проверка прав
sudo mysql -e "SHOW GRANTS FOR 'intern_user'@'localhost';"

# Логи Apache
sudo tail -f /var/log/apache2/error.log

# Проверка модулей (если apache2ctl не в PATH)
ls /etc/apache2/mods-enabled/ | grep php
# или
sudo /usr/sbin/apache2ctl -M | grep php
```
