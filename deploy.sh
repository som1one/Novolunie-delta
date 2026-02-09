#!/bin/bash

# Настройки сервера (измените на свои)
SERVER="user@your-server-ip"
REMOTE_PATH="/var/www/novolunie"

echo "🚀 Начинаем деплой..."

# Загрузка файлов на сервер
echo "📤 Загрузка файлов на сервер..."
rsync -avz --exclude '.git' --exclude 'node_modules' --exclude '*.md' --exclude 'deploy.sh' \
  ./ $SERVER:$REMOTE_PATH/

# Обновление прав доступа
echo "🔐 Обновление прав доступа..."
ssh $SERVER "sudo chown -R www-data:www-data $REMOTE_PATH && sudo chmod -R 755 $REMOTE_PATH"

# Перезагрузка Nginx
echo "🔄 Перезагрузка Nginx..."
ssh $SERVER "sudo nginx -t && sudo systemctl reload nginx"

echo "✅ Готово! Сайт обновлен."
