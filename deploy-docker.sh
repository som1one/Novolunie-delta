#!/bin/bash

# Настройки сервера (измените на свои)
SERVER="user@your-server-ip"
REMOTE_PATH="~/novolunie"

echo "🚀 Деплой через Docker..."

# Загрузка файлов на сервер
echo "📤 Загрузка файлов на сервер..."
rsync -avz --exclude '.git' --exclude 'node_modules' --exclude '*.md' --exclude 'deploy*.sh' \
  ./ $SERVER:$REMOTE_PATH/

# Пересборка и перезапуск контейнера на сервере
echo "🔨 Пересборка Docker образа..."
ssh $SERVER "cd $REMOTE_PATH && docker compose up -d --build"

# Проверка статуса
echo "📊 Проверка статуса контейнера..."
ssh $SERVER "cd $REMOTE_PATH && docker compose ps"

echo "✅ Готово! Сайт обновлен."
