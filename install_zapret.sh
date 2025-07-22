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

# Создание скрипта обновления
create_update_script() {
    log_info "Создание скрипта автоматического обновления..."
    
    cat > /usr/local/bin/update_zapret.sh << 'EOF'
#!/bin/bash

# Скрипт автоматического обновления zapret.dat
# Запускается ежедневно в 0:00

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
    log_message "zapret.dat не изменился, перезапуск не требуется"
    rm "$TEMP_FILE"
    exit 0
fi

# Замена файла
mv "$TEMP_FILE" "$ZAPRET_PATH"
log_message "zapret.dat обновлен"

# Перезапуск RemnaNode
if [[ -d "$REMNANODE_PATH" ]] && [[ -f "$REMNANODE_PATH/docker-compose.yml" ]]; then
    log_message "Перезапуск RemnaNode..."
    cd "$REMNANODE_PATH"
    docker compose pull >> "$LOG_FILE" 2>&1
    docker compose down >> "$LOG_FILE" 2>&1
    docker compose up -d >> "$LOG_FILE" 2>&1
    log_message "RemnaNode перезапущен"
else
    log_message "WARNING: Директория RemnaNode не найдена в $REMNANODE_PATH"
fi

log_message "Обновление завершено"
EOF

    chmod +x /usr/local/bin/update_zapret.sh
    log_success "Скрипт обновления создан в /usr/local/bin/update_zapret.sh"
}

# Настройка cron для автоматического обновления
setup_cron() {
    log_info "Настройка автоматического обновления через cron..."
    
    # Создание задачи cron
    CRON_JOB="0 0 * * * /usr/local/bin/update_zapret.sh"
    
    # Проверка существования задачи
    if crontab -l 2>/dev/null | grep -q "update_zapret.sh"; then
        log_warning "Задача cron уже существует"
    else
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        log_success "Задача cron добавлена: ежедневное обновление в 0:00"
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
    
    # Копирование zapret.dat в директорию проекта
    if [[ -f "/usr/local/share/xray/zapret.dat" ]]; then
        cp /usr/local/share/xray/zapret.dat /opt/remnanode/zapret.dat
        log_success "zapret.dat скопирован в /opt/remnanode/"
    fi
}

# Перезапуск RemnaNode
restart_remnanode() {
    log_info "Перезапуск RemnaNode для применения изменений..."
    
    if [[ -d "/opt/remnanode" ]] && [[ -f "/opt/remnanode/docker-compose.yml" ]]; then
        cd /opt/remnanode
        
        # Проверка наличия Docker Compose
        if ! command -v docker &> /dev/null; then
            log_error "Docker не установлен"
            return 1
        fi
        
        # Обновление и перезапуск
        docker compose pull
        docker compose down
        docker compose up -d
        
        log_success "RemnaNode успешно перезапущен"
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
    setup_cron
    update_docker_compose
    restart_remnanode
    
    log_success "Установка завершена!"
    log_info "zapret.dat будет автоматически обновляться ежедневно в 0:00"
    log_info "Логи обновлений можно найти в /var/log/zapret_update.log"
}

# Запуск основной функции
main "$@"