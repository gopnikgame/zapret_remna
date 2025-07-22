# zapret_remna
Скрипт добавляющий на ноду zapret.dat от kutovoys c авто обновлением.

## Описание

Этот скрипт автоматически:
- Скачивает актуальный файл `zapret.dat` с GitHub репозитория kutovoys
- Создает директорию `/usr/local/share/xray/` для хранения файла
- Настраивает автоматическое ежедневное обновление в 0:00 через cron
- Обновляет `docker-compose.yml` для RemnaNode, добавляя volume с zapret.dat
- Перезапускает RemnaNode для применения изменений

## Требования

- Операционная система Linux
- Права root (для установки)
- Docker и Docker Compose
- curl или wget для скачивания файлов
- RemnaNode установленный в `/opt/remnanode`

## Установка

1. Клонируйте репозиторий или скачайте скрипт:
```bash
git clone https://github.com/yourusername/zapret_remna.git
cd zapret_remna
```

2. Сделайте скрипт исполняемым:
```bash
chmod +x install_zapret.sh
```

3. Запустите установку от имени root:
```bash
sudo ./install_zapret.sh
```

## Что делает скрипт

### Первоначальная установка:
1. **Создание директорий** - создает `/usr/local/share/xray/`
2. **Скачивание zapret.dat** - загружает последнюю версию с GitHub
3. **Создание скрипта обновления** - создает `/usr/local/bin/update_zapret.sh`
4. **Настройка cron** - добавляет задачу для ежедневного обновления в 0:00
5. **Обновление docker-compose.yml** - добавляет volume mapping для zapret.dat
6. **Перезапуск RemnaNode** - применяет изменения

### Автоматическое обновление:
- Каждый день в 0:00 запускается скрипт `/usr/local/bin/update_zapret.sh`
- Скрипт проверяет наличие новой версии zapret.dat
- При обнаружении изменений обновляет файл и перезапускает RemnaNode
- Логи сохраняются в `/var/log/zapret_update.log`

## Структура файлов после установки

```
/usr/local/share/xray/zapret.dat          # Основной файл zapret.dat
/usr/local/bin/update_zapret.sh           # Скрипт автоматического обновления
/opt/remnanode/zapret.dat                 # Копия для Docker volume
/opt/remnanode/docker-compose.yml         # Обновленный docker-compose.yml
/var/log/zapret_update.log                # Логи автоматических обновлений
```

## Пример docker-compose.yml после обновления

```yaml
services:
    remnanode:
        container_name: remnanode
        hostname: remnanode
        image: remnawave/node:latest
        restart: always
        network_mode: host
        env_file:
            - .env
        volumes:
            - './zapret.dat:/usr/local/share/xray/zapret.dat'
```

## Ручное обновление

Для ручного обновления zapret.dat выполните:
```bash
sudo /usr/local/bin/update_zapret.sh
```

## Удаление автоматического обновления

Для удаления задачи cron:
```bash
sudo crontab -e
# Удалите строку: 0 0 * * * /usr/local/bin/update_zapret.sh
```

## Логирование

Все операции автоматического обновления логируются в файл `/var/log/zapret_update.log`. 

Для просмотра последних логов:
```bash
sudo tail -f /var/log/zapret_update.log
```

## Устранение неполадок

### Проверка статуса cron задачи
```bash
sudo crontab -l | grep zapret
```

### Проверка существования файлов
```bash
ls -la /usr/local/share/xray/zapret.dat
ls -la /usr/local/bin/update_zapret.sh
ls -la /opt/remnanode/zapret.dat
```

### Ручная проверка Docker volume
```bash
cd /opt/remnanode
docker compose exec remnanode ls -la /usr/local/share/xray/
```

## Источник данных

Файл zapret.dat загружается с официального репозитория:
- **GitHub**: [kutovoys/ru_gov_zapret](https://github.com/kutovoys/ru_gov_zapret)
- **Прямая ссылка**: https://github.com/kutovoys/ru_gov_zapret/releases/latest/download/zapret.dat

## Лицензия

MIT License
