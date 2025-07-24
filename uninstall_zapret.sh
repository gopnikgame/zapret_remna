#!/bin/bash

# Скрипт для удаления zapret.dat и всех связанных компонентов
# Использование: sudo ./uninstall_zapret.sh

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода
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

# Подтверждение удаления
confirm_removal() {
    echo
    log_warning "Этот скрипт удалит:"
    echo "  - /usr/local/share/xray/zapret.dat"
    echo "  - /usr/local/bin/update_zapret.sh (ежедневное обновление файла)"
    echo "  - /usr/local/bin/update_remnanode_docker.sh (еженедельное обновление Docker)"
    echo "  - Обе задачи cron (ежедневную и еженедельную)"
    echo "  - /opt/remnanode/zapret.dat"
    echo "  - Volume из docker-compose.yml (с созданием резервной копии)"
    echo "  - /var/log/zapret_update.log"
    echo
    
    read -p "Вы уверены, что хотите продолжить? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Удаление отменено"
        exit 0
    fi
}

# Удаление задач cron
remove_cron() {
    log_info "Удаление задач cron..."
    
    # Получение текущих задач cron
    CURRENT_CRONTAB=$(crontab -l 2>/dev/null || echo "")
    
    # Удаление ежедневной задачи обновления zapret.dat
    if echo "$CURRENT_CRONTAB" | grep -q "update_zapret.sh"; then
        echo "$CURRENT_CRONTAB" | grep -v "update_zapret.sh" | crontab -
        log_success "Ежедневная задача обновления zapret.dat удалена"
    else
        log_warning "Ежедневная задача cron не найдена"
    fi
    
    # Обновление списка задач после первого удаления
    CURRENT_CRONTAB=$(crontab -l 2>/dev/null || echo "")
    
    # Удаление еженедельной задачи обновления Docker
    if echo "$CURRENT_CRONTAB" | grep -q "update_remnanode_docker.sh"; then
        echo "$CURRENT_CRONTAB" | grep -v "update_remnanode_docker.sh" | crontab -
        log_success "Еженедельная задача обновления Docker удалена"
    else
        log_warning "Еженедельная задача cron не найдена"
    fi
}

# Удаление файлов
remove_files() {
    log_info "Удаление файлов..."
    
    # Основной файл zapret.dat
    if [[ -f "/usr/local/share/xray/zapret.dat" ]]; then
        rm -f "/usr/local/share/xray/zapret.dat"
        log_success "Удален /usr/local/share/xray/zapret.dat"
    fi
    
    # Скрипт ежедневного обновления файла
    if [[ -f "/usr/local/bin/update_zapret.sh" ]]; then
        rm -f "/usr/local/bin/update_zapret.sh"
        log_success "Удален /usr/local/bin/update_zapret.sh"
    fi
    
    # Скрипт еженедельного обновления Docker
    if [[ -f "/usr/local/bin/update_remnanode_docker.sh" ]]; then
        rm -f "/usr/local/bin/update_remnanode_docker.sh"
        log_success "Удален /usr/local/bin/update_remnanode_docker.sh"
    fi
    
    # Копия в директории проекта для Docker volume
    if [[ -f "/opt/remnanode/zapret.dat" ]]; then
        rm -f "/opt/remnanode/zapret.dat"
        log_success "Удален /opt/remnanode/zapret.dat"
    fi
    
    # Файл логов
    if [[ -f "/var/log/zapret_update.log" ]]; then
        rm -f "/var/log/zapret_update.log"
        log_success "Удален /var/log/zapret_update.log"
    fi
}

# Обновление docker-compose.yml (удаление volume)
update_docker_compose() {
    log_info "Обновление docker-compose.yml..."
    
    DOCKER_COMPOSE_PATH="/opt/remnanode/docker-compose.yml"
    
    if [[ -f "$DOCKER_COMPOSE_PATH" ]]; then
        # Создание резервной копии
        cp "$DOCKER_COMPOSE_PATH" "$DOCKER_COMPOSE_PATH.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Создана резервная копия docker-compose.yml"
        
        # Удаление строки с zapret.dat volume
        if grep -q "zapret.dat:/usr/local/share/xray/zapret.dat" "$DOCKER_COMPOSE_PATH"; then
            sed -i '/zapret\.dat:\/usr\/local\/share\/xray\/zapret\.dat/d' "$DOCKER_COMPOSE_PATH"
            
            # Удаление пустой секции volumes, если она стала пустой
            if grep -A1 "volumes:" "$DOCKER_COMPOSE_PATH" | grep -q "^\s*$"; then
                sed -i '/volumes:/{N;/^\s*volumes:\s*$/d;}' "$DOCKER_COMPOSE_PATH"
            fi
            
            log_success "Volume для zapret.dat удален из docker-compose.yml"
        else
            log_warning "Volume для zapret.dat не найден в docker-compose.yml"
        fi
    else
        log_warning "Файл docker-compose.yml не найден"
    fi
}

# Перезапуск RemnaNode
restart_remnanode() {
    log_info "Перезапуск RemnaNode..."
    
    if [[ -d "/opt/remnanode" ]] && [[ -f "/opt/remnanode/docker-compose.yml" ]]; then
        cd /opt/remnanode
        
        if command -v docker &> /dev/null; then
            docker compose pull
            docker compose down
            docker compose up -d
            log_success "RemnaNode перезапущен"
        else
            log_warning "Docker не найден, перезапуск пропущен"
        fi
    else
        log_warning "RemnaNode не найден, перезапуск пропущен"
    fi
}

# Очистка пустых директорий
cleanup_directories() {
    log_info "Очистка пустых директорий..."
    
    # Проверка и удаление пустой директории xray
    if [[ -d "/usr/local/share/xray" ]] && [[ -z "$(ls -A /usr/local/share/xray)" ]]; then
        rmdir "/usr/local/share/xray" 2>/dev/null
        log_success "Удалена пустая директория /usr/local/share/xray"
    fi
}

# Основная функция
main() {
    log_info "Запуск удаления zapret.dat"
    
    check_root
    confirm_removal
    
    remove_cron
    remove_files
    update_docker_compose
    restart_remnanode
    cleanup_directories
    
    echo
    log_success "Удаление завершено!"
    log_info "Все компоненты zapрет.dat были удалены из системы:"
    log_info "✓ Ежедневное обновление файла zapret.dat"
    log_info "✓ Еженедельное обновление Docker контейнера"
    log_info "✓ Все связанные файлы и логи"
    log_info "Резервные копии docker-compose.yml сохранены в /opt/remnanode/"
}

# Запуск основной функции
main "$@"