#!/bin/bash
# Быстрая настройка сервера Ubuntu - скопируйте и выполните на сервере

# 1. Обновление системы
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git nano ufw

# 2. Установка Docker
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
sudo apt install -y ca-certificates curl gnupg lsb-release
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 3. Добавление пользователя в группу docker
sudo usermod -aG docker $USER
newgrp docker

# 4. Настройка файрвола
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
echo "y" | sudo ufw enable

# 5. Создание директории проекта
mkdir -p ~/novolunie
cd ~/novolunie

# 6. Клонирование репозитория (или загрузка файлов)
# git clone https://github.com/som1one/Novolunie-delta.git .

# 7. Запуск контейнера
# docker compose up -d --build

echo "✅ Настройка завершена!"
echo "Следующие шаги:"
echo "1. Загрузите файлы проекта в ~/novolunie"
echo "2. Выполните: cd ~/novolunie && docker compose up -d --build"
