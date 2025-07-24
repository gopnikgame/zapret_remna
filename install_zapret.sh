#!/bin/bash

# Скрипт для установки и настройки автоматического обновления zapret.dat
# Автор: zapret_remna

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка запуска от root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Этот скрипт должен быть запущен от имени root"
        exit 1
    fi
}

# Создание директории для zapret.dat
create_directories() {
    log_info "Создание необходимых директорий..."
    mkdir -p /usr/local/share/xray/
    log_success "Директория /usr/local/share/xray/ создана"
}

# Скачивание zapret.dat
download_zapret() {
    log_info "Скачивание zapret.dat..."
    
    # URL для скачивания
    ZAPRET_URL="https://github.com/kutovoys/ru_gov_zapret/releases/latest/download/zapret.dat"
    ZAPRET_PATH="/usr/local/share/xray/zapret.dat"
    
    # Скачивание с помощью curl или wget
    if command -v curl &> /dev/null; then
        curl -L -o "$ZAPRET_PATH" "$ZAPRET_URL"
    elif command -v wget &> /dev/null; then
        wget -O "$ZAPRET_PATH" "$ZAPRET_URL"
    else
        log_error "Не найден curl или wget для скачивания файла"
        exit 1
    fi
    
    if [[ -f "$ZAPRET_PATH" ]]; then
        log_success "zapret.dat успешно скачан в $ZAPRET_PATH"
    else
        log_error "Ошибка при скачивании zapret.dat"
        exit 1
    fi
}

# Создание скрипта обновления zapret.dat (без перезапуска Docker)
create_update_script() {
    log_info "Создание скрипта автоматического обновления zapret.dat..."
    
    cat > /usr/local/bin/update_zapret.sh << 'EOF'
#!/bin/bash

# Скрипт автоматического обновления zapret.dat
# Запускается ежедневно в 0:00
# НЕ перезапускает Docker контейнер (volume остается активным)

ZAPRET_URL="https://github.com/kutovoys/ru_gov_zapret/releases/latest/download/zapret.dat"
ZAPRET_PATH="/usr/local/share/xray/zapret.dat"
REMNANODE_PATH="/opt/remnanode"
LOG_FILE="/var/log/zapret_update.log"

# Функция логирования
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_message "Начало обновления zapret.dat"

# Скачивание нового файла
TEMP_FILE="/tmp/zapret.dat.new"

if command -v curl &> /dev/null; then
    curl -L -o "$TEMP_FILE" "$ZAPRET_URL" 2>> "$LOG_FILE"
elif command -v wget &> /dev/null; then
    wget -O "$TEMP_FILE" "$ZAPRET_URL" 2>> "$LOG_FILE"
else
    log_message "ERROR: Не найден curl или wget"
    exit 1
fi

# Проверка успешности скачивания
if [[ ! -f "$TEMP_FILE" ]] || [[ ! -s "$TEMP_FILE" ]]; then
    log_message "ERROR: Ошибка при скачивании zapret.dat"
    exit 1
fi

# Проверка изменений в файле
if [[ -f "$ZAPRET_PATH" ]] && cmp -s "$TEMP_FILE" "$ZAPRET_PATH"; then
    log_message "zapret.dat не изменился, обновление не требуется"
    rm "$TEMP_FILE"
    exit 0
fi

# Замена основного файла
mv "$TEMP_FILE" "$ZAPRET_PATH"
log_message "zapret.dat обновлен в $ZAPRET_PATH"

# Копирование обновленного файла в директорию RemnaNode для Docker volume
if [[ -d "$REMNANODE_PATH" ]]; then
    cp "$ZAPRET_PATH" "$REMNANODE_PATH/zapret.dat"
    log_message "zapret.dat скопирован в $REMNANODE_PATH/zapret.dat"
    log_message "Docker контейнер будет использовать обновленный файл через volume (перезапуск не требуется)"
else
    log_message "WARNING: Директория RemnaNode не найдена в $REMNANODE_PATH"
fi

log_message "Обновление zapret.dat завершено (без перезапуска Docker)"
EOF

    chmod +x /usr/local/bin/update_zapret.sh
    log_success "Скрипт обновления zapret.dat создан в /usr/local/bin/update_zapret.sh"
}

# Создание скрипта еженедельного обновления Docker контейнера
create_docker_update_script() {
    log_info "Создание скрипта еженедельного обновления Docker контейнера..."
    
    cat > /usr/local/bin/update_remnanode_docker.sh << 'EOF'
#!/bin/bash

# Скрипт еженедельного обновления Docker контейнера RemnaNode
# Запускается по воскресеньям в 23:30 для поддержания актуальной версии

REMNANODE_PATH="/opt/remnanode"
LOG_FILE="/var/log/zapret_update.log"

# Функция логирования
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_message "Начало еженедельного обновления Docker контейнера RemnaNode"

# Проверка наличия docker-compose.yml
if [[ -d "$REMNANODE_PATH" ]] && [[ -f "$REMNANODE_PATH/docker-compose.yml" ]]; then
    log_message "Обновление Docker образа и перезапуск RemnaNode..."
    cd "$REMNANODE_PATH"
    
    # Обновление образа и перезапуск контейнера
    docker compose pull >> "$LOG_FILE" 2>&1
    docker compose down >> "$LOG_FILE" 2>&1
    docker compose up -d >> "$LOG_FILE" 2>&1
    
    log_message "RemnaNode Docker контейнер успешно обновлен и перезапущен"
else
    log_message "ERROR: Файл docker-compose.yml не найден в $REMNANODE_PATH"
    exit 1
fi

log_message "Еженедельное обновление Docker контейнера завершено"
EOF

    chmod +x /usr/local/bin/update_remnanode_docker.sh
    log_success "Скрипт еженедельного обновления Docker создан в /usr/local/bin/update_remnanode_docker.sh"
}

# Настройка cron для автоматического обновления
setup_cron() {
    log_info "Настройка автоматического обновления через cron..."
    
    # Ежедневное обновление zapret.dat в 0:00 (без перезапуска Docker)
    DAILY_CRON_JOB="0 0 * * * /usr/local/bin/update_zapret.sh"
    
    # Еженедельное обновление Docker контейнера по воскресеньям в 23:30
    WEEKLY_CRON_JOB="30 23 * * 0 /usr/local/bin/update_remnanode_docker.sh"
    
    # Получение текущих задач cron
    CURRENT_CRONTAB=$(crontab -l 2>/dev/null || echo "")
    
    # Проверка и добавление ежедневной задачи
    if echo "$CURRENT_CRONTAB" | grep -q "update_zapret.sh"; then
        log_warning "Ежедневная задача обновления zapret.dat уже существует"
    else
        (echo "$CURRENT_CRONTAB"; echo "$DAILY_CRON_JOB") | crontab -
        log_success "Ежедневная задача обновления zapret.dat добавлена: каждый день в 0:00"
    fi
    
    # Проверка и добавление еженедельной задачи
    if echo "$CURRENT_CRONTAB" | grep -q "update_remnanode_docker.sh"; then
        log_warning "Еженедельная задача обновления Docker уже существует"
    else
        (crontab -l 2>/dev/null; echo "$WEEKLY_CRON_JOB") | crontab -
        log_success "Еженедельная задача обновления Docker добавлена: по воскресеньям в 23:30"
    fi
}

# Обновление docker-compose.yml
update_docker_compose() {
    log_info "Обновление docker-compose.yml..."
    
    DOCKER_COMPOSE_PATH="/opt/remnanode/docker-compose.yml"
    
    if [[ ! -f "$DOCKER_COMPOSE_PATH" ]]; then
        log_warning "Файл $DOCKER_COMPOSE_PATH не найден, создание базового файла..."
        mkdir -p /opt/remnanode
        
        cat > "$DOCKER_COMPOSE_PATH" << 'EOF'
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
EOF
    else
        # Проверка наличия volume в существующем файле
        if grep -q "zapret.dat:/usr/local/share/xray/zapret.dat" "$DOCKER_COMPOSE_PATH"; then
            log_warning "Volume для zapret.dat уже настроен в docker-compose.yml"
        else
            # Создание резервной копии
            cp "$DOCKER_COMPOSE_PATH" "$DOCKER_COMPOSE_PATH.backup"
            log_info "Создана резервная копия: $DOCKER_COMPOSE_PATH.backup"
            
            # Добавление volume секции
            if grep -q "volumes:" "$DOCKER_COMPOSE_PATH"; then
                # volumes секция уже существует, добавляем наш volume
                sed -i '/volumes:/a\            - '\''./zapret.dat:/usr/local/share/xray/zapret.dat'\''' "$DOCKER_COMPOSE_PATH"
            else
                # volumes секции нет, создаем её
                sed -i '/env_file:/a\        volumes:\n            - '\''./zapret.dat:/usr/local/share/xray/zapret.dat'\''' "$DOCKER_COMPOSE_PATH"
            fi
            log_success "Volume для zapret.dat добавлен в docker-compose.yml"
        fi
    fi
    
    # Копирование zapret.dat в директорию проекта для Docker volume
    if [[ -f "/usr/local/share/xray/zapret.dat" ]]; then
        cp /usr/local/share/xray/zapret.dat /opt/remnanode/zapret.dat
        log_success "zapret.dat скопирован в /opt/remnanode/ для Docker volume"
    fi
    
    log_success "docker-compose.yml настроен для использования ./zapret.dat"
}

# Перезапуск RemnaNode (только при первой установке)
restart_remnanode() {
    log_info "Перезапуск RemnaNode для применения изменений при первой установке..."
    
    if [[ -d "/opt/remnanode" ]] && [[ -f "/opt/remnanode/docker-compose.yml" ]]; then
        cd /opt/remnanode
        
        # Проверка наличия Docker Compose
        if ! command -v docker &> /dev/null; then
            log_error "Docker не установлен"
            return 1
        fi
        
        # Обновление и перезапуск для применения нового volume
        log_info "Первая установка: обновление образа и перезапуск для применения volume"
        docker compose pull
        docker compose down
        docker compose up -d
        
        log_success "RemnaNode успешно перезапущен с новым volume zapret.dat"
        log_info "В дальнейшем при ежедневных обновлениях файла Docker перезапускаться не будет"
        log_info "Еженедельное обновление Docker контейнера настроено на воскресенье 23:30"
    else
        log_error "Директория /opt/remnanode не найдена или отсутствует docker-compose.yml"
    fi
}

# Основная функция
main() {
    log_info "Запуск установки zapret.dat с автоматическим обновлением"
    
    check_root
    create_directories
    download_zapret
    create_update_script
    create_docker_update_script
    setup_cron
    update_docker_compose
    restart_remnanode
    
    log_success "Установка завершена!"
    log_info "Настроена следующая система обновлений:"
    log_info "📅 Ежедневно в 0:00 - обновление zapret.dat (без перезапуска Docker)"
    log_info "🔄 По воскресеньям в 23:30 - обновление Docker контейнера RemnaNode"
    log_info "📊 Логи всех операций: /var/log/zapret_update.log"
}

# Запуск основной функции
main "$@"