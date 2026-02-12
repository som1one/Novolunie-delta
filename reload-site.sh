#!/bin/bash

# Скрипт для перезагрузки сайта после обновления из Git

echo "🔄 Перезагрузка сайта"
echo "===================="
echo ""

cd ~/novolunie || exit 1

echo "1️⃣ Обновление из Git..."
git pull origin main

if [ $? -ne 0 ]; then
    echo "❌ Ошибка при обновлении из Git!"
    exit 1
fi

echo "✅ Код обновлен"
echo ""

echo "2️⃣ Определение пути Nginx..."
NGINX_ROOT=$(sudo grep -r "root" /etc/nginx/sites-enabled/ 2>/dev/null | grep -v "#" | head -1 | awk '{print $2}' | tr -d ';' || echo "")

if [ -z "$NGINX_ROOT" ]; then
    NGINX_ROOT=$(sudo grep -E "^\s*root" /etc/nginx/nginx.conf 2>/dev/null | head -1 | awk '{print $2}' | tr -d ';' || echo "")
fi

if [ -z "$NGINX_ROOT" ]; then
    NGINX_ROOT="/var/www/html"
fi

echo "✅ Root: $NGINX_ROOT"
echo ""

echo "3️⃣ Копирование файлов в $NGINX_ROOT..."
sudo mkdir -p "$NGINX_ROOT"
sudo cp -r index.html components styles js assets "$NGINX_ROOT/" 2>/dev/null || true
sudo chown -R www-data:www-data "$NGINX_ROOT" 2>/dev/null || true
sudo find "$NGINX_ROOT" -type f -exec chmod 644 {} \; 2>/dev/null || true
sudo find "$NGINX_ROOT" -type d -exec chmod 755 {} \; 2>/dev/null || true

echo "✅ Файлы скопированы"
echo ""

echo "4️⃣ Проверка конфигурации Nginx..."
sudo nginx -t

if [ $? -ne 0 ]; then
    echo "❌ Ошибка в конфигурации Nginx!"
    echo "Исправьте ошибки перед перезагрузкой"
    exit 1
fi

echo "✅ Конфигурация корректна"
echo ""

echo "5️⃣ Перезагрузка Nginx..."
sudo systemctl reload nginx

if [ $? -eq 0 ]; then
    echo "✅ Nginx перезагружен"
else
    echo "⚠️  Попытка перезапуска..."
    sudo systemctl restart nginx
    if [ $? -eq 0 ]; then
        echo "✅ Nginx перезапущен"
    else
        echo "❌ Ошибка при перезагрузке Nginx!"
        exit 1
    fi
fi

echo ""
echo "6️⃣ Проверка статуса Nginx..."
sudo systemctl status nginx --no-pager -l | head -5

echo ""
echo "✅ Сайт перезагружен!"
echo ""
echo "📋 Проверьте сайт:"
echo "   https://e-novolunie.ru"
