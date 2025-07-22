# zapret_remna

[![GitHub](https://img.shields.io/badge/GitHub-zapret__remna-blue?logo=github)](https://github.com/gopnikgame/zapret_remna)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Скрипт для автоматической установки и обновления `zapret.dat` от kutovoys на RemnaNode с системой автоматического обновления.

## 🚀 Описание

Этот скрипт автоматически:
- 📥 Скачивает актуальный файл `zapret.dat` с GitHub репозитория [kutovoys/ru_gov_zapрет](https://github.com/kutovoys/ru_gov_zapрет)
- 📁 Создает необходимые директории для хранения файла
- ⏰ Настраивает автоматическое ежедневное обновление в 0:00 через cron
- 🐳 Обновляет `docker-compose.yml` для RemnaNode, добавляя volume с zapret.dat
- 🔄 Автоматически перезапускает RemnaNode при обновлениях
- 📊 Ведет подробные логи всех операций

## 📋 Требования

- 🐧 Операционная система Linux
- 🔑 Права root (для установки)
- 🐳 Docker и Docker Compose
- 📡 curl или wget для скачивания файлов
- 🏠 RemnaNode установленный в `/opt/remnanode`

## ⚡ Быстрая установка

```bash
# Клонирование репозитория
git clone https://github.com/gopnikgame/zapret_remna.git
cd zapret_remna

# Установка и запуск
chmod +x install_zapret.sh
sudo ./install_zapret.sh
```

## 📖 Подробная инструкция по установке

### 1. Скачивание проекта

**Вариант A: Через Git**
```bash
git clone https://github.com/gopnikgame/zapret_remna.git
cd zapret_remna
```

**Вариант B: Прямое скачивание**
```bash
wget https://github.com/gopnikgame/zapret_remna/archive/main.zip
unzip main.zip
cd zapret_remna-main
```

### 2. Подготовка скриптов

```bash
# Сделать скрипты исполняемыми
chmod +x install_zapret.sh uninstall_zapret.sh
```

### 3. Запуск установки

```bash
# Запуск от имени root
sudo ./install_zapret.sh
```

## 🔧 Что делает скрипт установки

### Первоначальная установка:
1. **🏗️ Создание директорий** - создает `/usr/local/share/xray/`
2. **📥 Скачивание zapret.dat** - загружает последнюю версию с GitHub
3. **📝 Создание скрипта обновления** - создает `/usr/local/bin/update_zapret.sh`
4. **⏰ Настройка cron** - добавляет задачу для ежедневного обновления в 0:00
5. **🐳 Обновление docker-compose.yml** - добавляет volume mapping для zapret.dat
6. **🔄 Перезапуск RemnaNode** - применяет изменения

### Автоматическое обновление:
- ⏰ Каждый день в 0:00 запускается скрипт `/usr/local/bin/update_zapret.sh`
- 🔍 Скрипт проверяет наличие новой версии zapret.dat
- 📊 При обнаружении изменений обновляет файл и перезапускает RemnaNode
- 📋 Все операции логируются в `/var/log/zapret_update.log`

## 📂 Структура файлов после установки

```
/usr/local/share/xray/zapret.dat          # 📄 Основной файл zapрет.dat (источник)
 /usr/local/bin/update_zapret.sh           # 🔄 Скрипт автоматического обновления
/opt/remnanode/zapret.dat                 # 📋 Копия для Docker volume
/opt/remnanode/docker-compose.yml         # 🐳 Обновленный docker-compose.yml
/var/log/zapret_update.log                # 📊 Логи автоматических обновлений
```

## 🐳 Пример docker-compose.yml после обновления

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

## 🔧 Управление

### Ручное обновление
Для ручного обновления zapret.dat выполните:
```bash
sudo /usr/local/bin/update_zapret.sh
```

### Просмотр логов
```bash
# Просмотр последних логов
sudo tail -f /var/log/zapret_update.log

# Просмотр всех логов
sudo cat /var/log/zapret_update.log
```

### Проверка статуса cron
```bash
# Проверка наличия задачи
sudo crontab -l | grep zapret

# Проверка работы cron
sudo systemctl status cron
```

## 🗑️ Удаление

Для полного удаления zapret.dat и всех компонентов:

```bash
sudo ./uninstall_zapret.sh
```

Скрипт удаления:
- ❌ Удаляет основной файл zapрет.dat из /usr/local/share/xray/
- ❌ Удаляет копию zapрет.dat из /opt/remnanode/
- ⏰ Удаляет задачу cron
- 🐳 Удаляет volume из docker-compose.yml (с созданием резервной копии)
- 📊 Удаляет логи
- 🧹 Очищает пустые директории

## 🛠️ Устранение неполадок

### Проверка существования файлов
```bash
ls -la /usr/local/share/xray/zapret.dat
ls -la /usr/local/bin/update_zapret.sh
ls -la /opt/remnanode/zapret.dat
```

### Проверка Docker volume
```bash
cd /opt/remnanode
docker compose exec remnanode ls -la /usr/local/share/xray/
```

### Проверка статуса контейнера
```bash
docker ps | grep remnanode
docker logs remnanode
```

### Тестирование скачивания
```bash
# Проверка доступности файла
curl -I https://github.com/kutovoys/ru_gov_zапрет/releases/latest/download/zapret.dat
```

## 📊 Источник данных

Файл zapret.dat загружается с официального репозитория:
- **GitHub**: [kutovoys/ru_gov_zапрет](https://github.com/kutovoys/ru_gov_zapрет)
- **Прямая ссылка**: `https://github.com/kutovoys/ru_gov_zапрет/releases/latest/download/zapret.dat`

## 🤝 Вклад в проект

Мы приветствуем вклад в развитие проекта! Если у вас есть предложения по улучшению:

1. 🍴 Форкните репозиторий
2. 🌿 Создайте ветку для изменений (`git checkout -b feature/amazing-feature`)
3. 💾 Закоммитьте изменения (`git commit -m 'Add some amazing feature'`)
4. 📤 Запушьте ветку (`git push origin feature/amazing-feature`)
5. 🔄 Откройте Pull Request

## 📝 Лицензия

Этот проект распространяется под лицензией MIT. Подробности в файле [LICENSE](LICENSE).

## ⭐ Поддержка проекта

Если проект оказался полезным, поставьте звезду на GitHub!

[![GitHub звезды](https://img.shields.io/github/stars/gopnikgame/zapret_remna.svg?style=social&label=Star)](https://github.com/gopnikgame/zapret_remna)

---

**Примечание**: Этот скрипт разработан для упрощения работы с zapret.dat от kutovoys. Убедитесь, что использование соответствует законодательству вашей страны.
