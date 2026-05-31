-- scripts/setup-mysql.sql
-- Создание базы данных для проекта
CREATE DATABASE IF NOT EXISTS internship_db 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

-- Создание пользователя с паролем
CREATE USER IF NOT EXISTS 'intern_user'@'localhost' 
    IDENTIFIED BY 'StrongP@ssw0rd!2026';

-- Предоставление прав только на нашу базу
GRANT ALL PRIVILEGES ON internship_db.* TO 'intern_user'@'localhost';

-- Применение изменений
FLUSH PRIVILEGES;

-- Проверка
SELECT User, Host FROM mysql.user WHERE User = 'intern_user';
SHOW DATABASES LIKE 'internship_db';