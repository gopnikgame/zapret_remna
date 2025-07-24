# zapret_remna

[![GitHub](https://img.shields.io/badge/GitHub-zapret__remna-blue?logo=github)](https://github.com/gopnikgame/zapret_remna)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Скрипт для автоматической установки и обновления `zapret.dat` от kutovoys на RemnaNode с оптимизированной системой автоматического обновления.

## 🚀 Описание

Этот скрипт автоматически:
- 📥 Скачивает актуальный файл `zapret.dat` с GitHub репозитория [kutovoys/ru_gov_zapрет](https://github.com/kutovoys/ru_gov_zапрет)
- 📁 Создает необходимые директории для хранения файла
- ⏰ Настраивает **оптимизированную** систему автоматического обновления:
  - 📅 **Ежедневно в 0:00** - обновление zapret.dat (без перезапуска Docker)
  - 🔄 **По воскресеньям в 23:30** - обновление Docker контейнера RemnaNode
- 🐳 Обновляет `docker-compose.yml` для RemnaNode, добавляя volume с zapret.dat
- 📊 Ведет подробные логи всех операций

## 💡 Особенности оптимизации

### 🎯 Умная система обновлений:
- **При первой установке**: Docker контейнер перезапускается для применения нового volume
- **При ежедневном обновлении**: Только обновляется файл zapret.dat (Docker не перезапускается, так как volume остается активным)
- **Еженедельное обновление**: Docker контейнер обновляется для поддержания актуальной версии RemnaNode

### ⚡ Преимущества:
- 🚀 **Быстрые ежедневные обновления** - без простоя сервиса
- 🔄 **Автоматическое поддержание актуальности** Docker образа
- 📊 **Минимальное потребление ресурсов** при обновлениях
- 🛡️ **Стабильная работа** без лишних перезапусков

## 📋 Требования

- 🐧 Операционная система Linux
- 🔑 Права root (для установки)
- 🐳 Docker и Docker Compose
- 📡 curl или wget для скачивания файлов
- 🏠 RemnaNode установленный в `/opt/remnanode`

## ⚡ Быстрая установка

```bash
wget -qO install_zapret.sh https://raw.githubusercontent.com/gopnikgame/zapret_remna/main/install_zapret.sh && chmod +x install_zapret.sh && sudo ./install_zapret.sh
```

```bash
wget -qO uninstall_zapret.sh https://raw.githubusercontent.com/gopnikgame/zapret_remna/main/uninstall_zapret.sh && chmod +x uninstall_zapret.sh && sudo ./uninstall_zapret.sh
```

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
3. **📝 Создание скриптов обновления**:
   - `/usr/local/bin/update_zapret.sh` - ежедневное обновление файла
   - `/usr/local/bin/update_remnanode_docker.sh` - еженедельное обновление контейнера
4. **⏰ Настройка cron** - добавляет две задачи:
   - Ежедневно в 0:00 - обновление zapret.dat
   - По воскресеньям в 23:30 - обновление Docker контейнера
5. **🐳 Обновление docker-compose.yml** - добавляет volume mapping для zapret.dat
6. **🔄 Перезапуск RemnaNode** - применяет изменения (только при первой установке)

### Автоматическое обновление:

#### 📅 Ежедневное обновление zapret.dat (0:00):
- 🔍 Проверяет наличие новой версии zapret.dat
- 📊 При обнаружении изменений обновляет файл
- ✅ **НЕ перезапускает** Docker контейнер (volume остается активным)
- 📋 Логирует все операции

#### 🔄 Еженедельное обновление контейнера (Воскресенье 23:30):
- 🐳 Обновляет Docker образ RemnaNode до последней версии
- 🔄 Перезапускает контейнер для применения обновлений
- 📊 Поддерживает актуальную версию системы

## 📂 Структура файлов после установки

```
/usr/local/share/xray/zapret.dat              # 📄 Основной файл zapрет.dat (источник)
/usr/local/bin/update_zapret.sh               # 📅 Скрипт ежедневного обновления файла
/usr/local/bin/update_remnanode_docker.sh     # 🔄 Скрипт еженедельного обновления Docker
/opt/remnanode/zapret.dat                     # 📋 Копия для Docker volume
/opt/remnanode/docker-compose.yml             # 🐳 Обновленный docker-compose.yml
/var/log/zapret_update.log                    # 📊 Единый лог всех обновлений
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

### Ручные обновления

**Обновление только zapret.dat (без перезапуска Docker):**
```bash
sudo /usr/local/bin/update_zapret.sh
```

**Обновление Docker контейнера RemnaNode:**
```bash
sudo /usr/local/bin/update_remnanode_docker.sh
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
# Проверка всех задач zapret
sudo crontab -l | grep zapret

# Проверка работы cron
sudo systemctl status cron
```

## ⏰ Расписание автоматических обновлений

| Время | Периодичность | Действие | Перезапуск Docker |
|-------|--------------|----------|------------------|
| **0:00** | Ежедневно | Обновление zapret.dat | ❌ Нет |
| **23:30** | По воскресеньям | Обновление Docker контейнера | ✅ Да |

## 🗑️ Удаление

Для полного удаления zapret.dat и всех компонентов:

```bash
sudo ./uninstall_zapret.sh
```

Скрипт удаления:
- ❌ Удаляет основной файл zapрет.dat из /usr/local/share/xray/
- ❌ Удаляет копию запрет.dat из /opt/remnanode/
- ❌ Удаляет оба скрипта обновления
- ⏰ Удаляет обе задачи cron (ежедневную и еженедельную)
- 🐳 Удаляет volume из docker-compose.yml (с созданием резервной копии)
- 📊 Удаляет логи
- 🧹 Очищает пустые директории

## 🛠️ Устранение неполадок

### Проверка существования файлов
```bash
ls -la /usr/local/share/xray/zapret.dat
ls -la /usr/local/bin/update_zapret.sh
ls -la /usr/local/bin/update_remnanode_docker.sh
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

### Проверка работы обновлений
```bash
# Тест ежедневного обновления
sudo /usr/local/bin/update_zapret.sh

# Тест еженедельного обновления Docker
sudo /usr/local/bin/update_remnanode_docker.sh

# Просмотр логов
sudo tail -20 /var/log/zapret_update.log
```

### Тестирование скачивания
```bash
# Проверка доступности файла
curl -I https://github.com/kutovoys/ru_gov_zапрет/releases/latest/download/zapret.dat
```

## 📊 Источник данных

Файл zapret.dat загружается с официального репозитория:
- **GitHub**: [kutovoys/ru_gov_zапрет](https://github.com/kutovoys/ru_gov_zапрет)
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
