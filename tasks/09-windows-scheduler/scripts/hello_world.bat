@echo off
:: hello_world.bat — ежедневный лог "Hello World"
:: Задание 9: Планировщик заданий Windows

set "LOGFILE=C:\Tasks\hello_world.log"

:: Создаём папку для лога, если её нет
if not exist "C:\Tasks" mkdir C:\Tasks

:: Получаем дату и время в стабильном формате: ГГГГ-ММ-ДД ЧЧ:ММ:СС
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2% %dt:~8,2%:%dt:~10,2%:%dt:~12,2%"

:: Записываем строку в лог-файл (добавление в конец файла)
echo Hello World: %TIMESTAMP% >> "%LOGFILE%"

:: Корректный код завершения для Планировщика заданий (0 = успех)
exit /b 0