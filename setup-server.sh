#!/bin/bash

# Скрипт автоматической настройки сервера Ubuntu для Novolunie
# Запускать от root или с sudo

set -e

echo "🚀 Настройка сервера Ubuntu для Novolunie..."
echo ""

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка прав root
if [ "$EUID" -ne 0 ]; then 
    error "Пожалуйста, запустите скрипт от root или с sudo"
    exit 1
fi

# Шаг 1: Обновление системы
info "Обновление системы..."
apt update
apt upgrade -y
apt install -y curl wget git nano ufw

# Шаг 2: Установка Docker
info "Установка Docker..."
apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
apt install -y ca-certificates curl gnupg lsb-release

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Добавляем текущего пользователя в группу docker
if [ -n "$SUDO_USER" ]; then
    usermod -aG docker $SUDO_USER
    info "Пользователь $SUDO_USER добавлен в группу docker"
fi

# Проверка Docker
if docker --version > /dev/null 2>&1; then
    info "Docker установлен: $(docker --version)"
else
    error "Ошибка установки Docker"
    exit 1
fi

# Шаг 3: Настройка файрвола
info "Настройка файрвола..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
echo "y" | ufw enable
info "Файрвол настроен"

# Шаг 4: Создание директории для проекта
PROJECT_DIR="/home/$SUDO_USER/novolunie"
if [ -z "$SUDO_USER" ]; then
    PROJECT_DIR="$HOME/novolunie"
fi

info "Создание директории проекта: $PROJECT_DIR"
mkdir -p $PROJECT_DIR

# Шаг 5: Настройка прав
if [ -n "$SUDO_USER" ]; then
    chown -R $SUDO_USER:$SUDO_USER $PROJECT_DIR
fi

info ""
info "✅ Базовая настройка сервера завершена!"
info ""
info "Следующие шаги:"
info "1. Выйдите и войдите снова (или выполните: newgrp docker)"
info "2. Перейдите в директорию: cd $PROJECT_DIR"
info "3. Клонируйте репозиторий: git clone https://github.com/som1one/Novolunie-delta.git ."
info "4. Или загрузите файлы через scp/rsync"
info "5. Запустите: docker compose up -d --build"
info ""
warn "Не забудьте выполнить 'newgrp docker' или перелогиниться!"
