# Задание 3: Установка WSL2, настройка Debian и базовых инструментов разработки

## Цель
Освоить работу с Windows Subsystem for Linux (WSL2), развернуть консольное окружение Debian, настроить репозитории, установить компиляторы и интерпретаторы, изучить интеграцию файловых систем Windows и Linux через точку монтирования `/mnt/`. Зафиксировать процесс в портфолио.

## Стек и инструменты
- **Хост:** Windows 10/11
- **Подсистема:** `WSL2` (ядро Linux, полная совместимость системных вызовов)
- **Дистрибутив:** `Debian 13 (Bookworm)` — консольный/минимальный режим
- **Пакеты:** `gcc`, `make`, `python3`, `python3-pip`, `mc`
- **CLI:** `wsl.exe`, `bash`, `apt`

## Чек-лист выполнения
- [x] Включены компоненты Windows: `WSL` и `Virtual Machine Platform`
- [x] Установлен и запущен WSL2 (по умолчанию версия 2)
- [x] Установлен дистрибутив Debian (`wsl --install`) [Вывод wsl -l -v в PowerShell](/tasks/03-wsl-debian/assets/01-wsl-version.png)
- [x] Выполнено обновление пакетов: `apt update && apt upgrade -y` [(успешное завершение)](/tasks/03-wsl-debian/assets/02-apt-install.png)
- [x] Установлены: `gcc`, `make`, `python3`, `python3-pip`, `mc`
- [x] Запущен `mc`, проверена навигация и выход (`F10`)
- [x] Изучена структура `/mnt/` (смонтированные диски Windows) [mc с открытой директорией /mnt/c/Windows/System32/](/tasks/03-wsl-debian/assets/03-mc-mnt-c.png)
- [x] Проверена совместимость и версии установленного ПО [Вывод python3 -V, gcc -v, pip3 -V](/tasks/03-wsl-debian/assets/04-versions-output.png)

## Краткая инструкция (Reference)
> Все команды выполняются внутри терминала WSL (Debian). При запросе `sudo` введите пароль, заданный при первом запуске дистрибутива.

**1. Установка и проверка WSL2 (из PowerShell)**
```powershell
# Включить компоненты и установить ядро (Win10 2004+ / Win11)
wsl --install -d Debian

# Если требуется вручную:
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
# Перезагрузить ПК, затем:
wsl --set-default-version 2
```
**2. Обновление системы**
```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt autoremove -y
```
**3. Установка инструментов разработки**
```bash
sudo apt install -y gcc make python3 python3-pip mc
# (Рекомендуется) Проверить версии
gcc --version
make --version
python3 --version
pip3 --version
```
**4. Запуск Midnight Commander и исследование `/mnt/`**
```bash
mc
# Внутри mc: перейдите в /mnt/ → /mnt/c/ → просмотрите содержимое диска Windows
# Выход: F10 или Esc+0
```
**Проверка результата (Success Criteria)**
| Компонент | Команда | Ожидаемый результат |
|------|------|---------|
| WSL версия | `wsl -l -v` (PowerShell) | `GNU Make x.x`|
| Компилятор | `gcc --version` | `gcc (Debian x.x.x-x) x.x.x` | 
| Сборка | `make --version` | `GNU Make x.x` |
| Python | `python3 --version && pip3 --version` | `Python 3.11.x` |
| Файловый менеджер | `mc` | Запуск двухпанельного интерфейса, навигация работает |
| Интеграция | `ls -la /mnt/c/` | Отображаются файлы диска `C:\` без ошибок доступа |


 **Рекомендации** 
* Производительность: Храните проекты внутри файловой системы Linux (`~`), а не в `/mnt/c/`. Доступ к `\\wsl$\` из проводника Windows работает быстро благодаря 9P-протоколу.
* Python алиас: В Debian `python` часто не установлен по умолчанию. Используйте `python3`. При необходимости создайте симлинк: `sudo ln -s /usr/bin/python3 /usr/local/bin/python`
* Альтернатива `gcc`/`make`: Пакет `build-essential` автоматически тянет `gcc`, `g++`, `make`, `dpkg-dev`. 
* Бэкап дистрибутива: `wsl --export Debian debian-backup.tar` → легко восстановить или перенести на другой ПК.
* Сброс окружения: `wsl --unregister Debian` полностью удаляет дистрибутив. Используйте только при критических сбоях.
