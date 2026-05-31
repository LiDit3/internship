#!/bin/bash
# scripts/check-mariadb.sh — проверка установки

echo "Проверка MariaDB..."

# Статус сервиса
sudo systemctl is-active mariadb && echo "Сервис запущен" || echo "Сервис не активен"

# Версия СУБД
mysql --version

# Список БД
sudo mysql -e "SHOW DATABASES;" | grep -E 'internship_db|Database'

# Пользователи
sudo mysql -e "SELECT User, Host, plugin FROM mysql.user WHERE User='intern_user';"

# Проверка phpMyAdmin
curl -s -o /dev/null -w " phpMyAdmin HTTP: %{http_code}\n" http://127.0.0.1:8080/phpmyadmin

echo "Проверка завершена"