#!/bin/bash

# Скрипт для проверки и исправления ссылок Telegram на сервере

echo "🔍 Проверка ссылок Telegram"
echo "=========================="
echo ""

cd ~/novolunie || exit 1

echo "1️⃣ Обновление из Git..."
git pull origin main

echo ""
echo "2️⃣ Проверка ссылок в файлах..."
echo ""

# Проверка index.html
echo "📄 index.html:"
grep -n "deltasmaxxx?text=" index.html | head -2

# Проверка components
echo ""
echo "📄 components/hero.html:"
grep -n "deltasmaxxx?text=" components/hero.html

echo ""
echo "📄 components/preorder.html:"
grep -n "deltasmaxxx?text=" components/preorder.html

echo ""
echo "3️⃣ Определение пути Nginx..."
NGINX_ROOT=$(sudo grep -r "root" /etc/nginx/sites-enabled/ 2>/dev/null | grep -v "#" | head -1 | awk '{print $2}' | tr -d ';' || echo "")

if [ -z "$NGINX_ROOT" ]; then
    NGINX_ROOT=$(sudo grep -E "^\s*root" /etc/nginx/nginx.conf 2>/dev/null | head -1 | awk '{print $2}' | tr -d ';' || echo "")
fi

if [ -z "$NGINX_ROOT" ]; then
    NGINX_ROOT="/var/www/html"
fi

echo "✅ Root: $NGINX_ROOT"

echo ""
echo "4️⃣ Проверка ссылок в файлах на сервере..."
if [ -f "$NGINX_ROOT/index.html" ]; then
    echo "📄 $NGINX_ROOT/index.html:"
    grep -n "deltasmaxxx?text=" "$NGINX_ROOT/index.html" | head -2
else
    echo "❌ Файл не найден: $NGINX_ROOT/index.html"
fi

echo ""
echo "5️⃣ Копирование обновленных файлов..."
sudo mkdir -p "$NGINX_ROOT"
sudo cp -r index.html components styles js assets "$NGINX_ROOT/" 2>/dev/null || true
sudo chown -R www-data:www-data "$NGINX_ROOT" 2>/dev/null || true
sudo find "$NGINX_ROOT" -type f -exec chmod 644 {} \; 2>/dev/null || true
sudo find "$NGINX_ROOT" -type d -exec chmod 755 {} \; 2>/dev/null || true

echo "✅ Файлы скопированы"

echo ""
echo "6️⃣ Проверка ссылок после копирования..."
if [ -f "$NGINX_ROOT/index.html" ]; then
    echo "📄 $NGINX_ROOT/index.html:"
    grep -n "deltasmaxxx?text=" "$NGINX_ROOT/index.html" | head -2
fi

echo ""
echo "7️⃣ Перезагрузка Nginx..."
sudo systemctl reload nginx

echo ""
echo "8️⃣ Проверка доступности ссылки..."
DOMAIN="e-novolunie.ru"
echo "Проверка: https://${DOMAIN}/"
curl -s "https://${DOMAIN}/" | grep -o "deltasmaxxx?text=[^\"]*" | head -2

echo ""
echo "✅ Проверка завершена!"
echo ""
echo "📋 Если ссылки не обновились:"
echo "   1. Очистите кэш браузера (Ctrl+Shift+R или Ctrl+F5)"
echo "   2. Проверьте в режиме инкогнито"
echo "   3. Проверьте логи: sudo tail -f /var/log/nginx/error.log"
