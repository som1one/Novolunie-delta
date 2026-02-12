#!/bin/bash

# Скрипт для исправления пути к логотипу

echo "🔧 Исправление пути к логотипу"
echo "==============================="
echo ""

cd ~/novolunie || exit 1

echo "1️⃣ Проверка конфигурации Nginx..."
NGINX_ROOT=$(sudo grep -r "root" /etc/nginx/sites-enabled/ 2>/dev/null | grep -v "#" | head -1 | awk '{print $2}' | tr -d ';' || echo "")

if [ -z "$NGINX_ROOT" ]; then
    NGINX_ROOT=$(sudo grep -E "^\s*root" /etc/nginx/nginx.conf 2>/dev/null | head -1 | awk '{print $2}' | tr -d ';' || echo "")
fi

if [ -n "$NGINX_ROOT" ]; then
    echo "✅ Root в Nginx: $NGINX_ROOT"
else
    echo "⚠️  Root не найден, используем стандартный: /var/www/html"
    NGINX_ROOT="/var/www/html"
fi

echo ""
echo "2️⃣ Проверка файла в репозитории..."
if [ ! -f "assets/logo.png" ]; then
    echo "❌ Логотип не найден в репозитории!"
    exit 1
fi

echo "✅ Логотип найден: assets/logo.png"
ls -lh assets/logo.png

echo ""
echo "3️⃣ Копирование в правильную папку: $NGINX_ROOT/assets/..."
sudo mkdir -p "$NGINX_ROOT/assets"
sudo cp assets/logo.png "$NGINX_ROOT/assets/logo.png"
sudo chmod 644 "$NGINX_ROOT/assets/logo.png"
sudo chown www-data:www-data "$NGINX_ROOT/assets/logo.png" 2>/dev/null || true

if [ -f "$NGINX_ROOT/assets/logo.png" ]; then
    echo "✅ Логотип скопирован: $NGINX_ROOT/assets/logo.png"
    ls -lh "$NGINX_ROOT/assets/logo.png"
else
    echo "❌ Ошибка при копировании!"
    exit 1
fi

echo ""
echo "4️⃣ Копирование всех файлов сайта..."
if [ "$NGINX_ROOT" != "/var/www/html" ]; then
    echo "Копирование в $NGINX_ROOT..."
    sudo mkdir -p "$NGINX_ROOT"
    sudo cp -r index.html components styles js assets "$NGINX_ROOT/" 2>/dev/null || true
    sudo chown -R www-data:www-data "$NGINX_ROOT" 2>/dev/null || true
    sudo find "$NGINX_ROOT" -type f -exec chmod 644 {} \; 2>/dev/null || true
    sudo find "$NGINX_ROOT" -type d -exec chmod 755 {} \; 2>/dev/null || true
    echo "✅ Файлы скопированы в $NGINX_ROOT"
fi

echo ""
echo "5️⃣ Перезагрузка Nginx..."
sudo systemctl reload nginx

if [ $? -eq 0 ]; then
    echo "✅ Nginx перезагружен"
else
    echo "⚠️  Ошибка при перезагрузке Nginx"
    sudo nginx -t
fi

echo ""
echo "6️⃣ Проверка доступности..."
DOMAIN="e-novolunie.ru"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://${DOMAIN}/assets/logo.png" 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Логотип доступен: https://${DOMAIN}/assets/logo.png"
elif [ "$HTTP_CODE" = "404" ]; then
    echo "❌ Логотип все еще недоступен (404)"
    echo ""
    echo "Проверьте:"
    echo "  1. Конфигурацию: sudo nginx -t"
    echo "  2. Логи: sudo tail -f /var/log/nginx/error.log"
    echo "  3. Путь: ls -la $NGINX_ROOT/assets/logo.png"
else
    echo "⚠️  Код ответа: $HTTP_CODE"
fi

echo ""
echo "✅ Готово!"
