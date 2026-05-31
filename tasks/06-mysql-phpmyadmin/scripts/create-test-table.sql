-- scripts/create-test-table.sql
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
SELECT * FROM test LIMIT 5;