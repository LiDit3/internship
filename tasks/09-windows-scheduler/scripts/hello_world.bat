:: hello_world.bat — ежедневный лог "Hello World"
:: Автор: ВашеИмя | Дата: 2026
set "LOGFILE=C:\Tasks\hello_world.log"
if not exist "C:\Tasks" mkdir C:\Tasks
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2% %dt:~8,2%:%dt:~10,2%:%dt:~12,2%"
echo [%TIMESTAMP%] Hello World >> "%LOGFILE%"
exit /b 0