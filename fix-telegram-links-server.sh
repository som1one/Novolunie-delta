#!/bin/bash

# Скрипт для исправления ссылок Telegram на сервере

echo "🔧 Исправление ссылок Telegram"
echo "==============================="
echo ""

cd ~/novolunie || exit 1

echo "1️⃣ Обновление из Git..."
git pull origin main

echo ""
echo "2️⃣ Поиск пути Nginx..."
echo ""

# Проверка sites-enabled
SITE_CONF=$(ls /etc/nginx/sites-enabled/* 2>/dev/null | head -1)
if [ -n "$SITE_CONF" ]; then
    echo "Найдена конфигурация: $SITE_CONF"
    NGINX_ROOT=$(sudo grep -E "^\s*root" "$SITE_CONF" 2>/dev/null | grep -v "#" | head -1 | awk '{print $2}' | tr -d ';' || echo "")
fi

# Если не нашли, проверяем nginx.conf
if [ -z "$NGINX_ROOT" ]; then
    echo "Проверка /etc/nginx/nginx.conf..."
    NGINX_ROOT=$(sudo grep -E "^\s*root" /etc/nginx/nginx.conf 2>/dev/null | grep -v "#" | head -1 | awk '{print $2}' | tr -d ';' || echo "")
fi

# Если все еще не нашли, проверяем стандартные пути
if [ -z "$NGINX_ROOT" ]; then
    echo "Проверка стандартных путей..."
    if [ -d "/var/www/e-novolunie.ru" ]; then
        NGINX_ROOT="/var/www/e-novolunie.ru"
    elif [ -d "/var/www/html" ]; then
        NGINX_ROOT="/var/www/html"
    else
        echo "❌ Не удалось определить путь!"
        echo "Проверьте конфигурацию Nginx вручную:"
        echo "   sudo grep -r 'root' /etc/nginx/sites-enabled/"
        exit 1
    fi
fi

echo "✅ Найден путь: $NGINX_ROOT"

echo ""
echo "3️⃣ Проверка текущих ссылок в файле на сервере..."
if [ -f "$NGINX_ROOT/index.html" ]; then
    echo "Текущие ссылки:"
    grep "deltasmaxxx?text=" "$NGINX_ROOT/index.html" | head -2
else
    echo "⚠️  Файл не найден: $NGINX_ROOT/index.html"
fi

echo ""
echo "4️⃣ Проверка ссылок в локальных файлах..."
echo "Локальные ссылки:"
grep "deltasmaxxx?text=" index.html | head -2

echo ""
echo "5️⃣ Копирование файлов в $NGINX_ROOT..."
sudo mkdir -p "$NGINX_ROOT"
sudo cp -r index.html components styles js assets "$NGINX_ROOT/" 2>/dev/null || true

if [ $? -eq 0 ]; then
    echo "✅ Файлы скопированы"
else
    echo "❌ Ошибка при копировании!"
    exit 1
fi

echo ""
echo "6️⃣ Установка прав доступа..."
sudo chown -R www-data:www-data "$NGINX_ROOT" 2>/dev/null || true
sudo find "$NGINX_ROOT" -type f -exec chmod 644 {} \; 2>/dev/null || true
sudo find "$NGINX_ROOT" -type d -exec chmod 755 {} \; 2>/dev/null || true

echo "✅ Права установлены"

echo ""
echo "7️⃣ Проверка ссылок после копирования..."
if [ -f "$NGINX_ROOT/index.html" ]; then
    echo "Ссылки в файле на сервере:"
    grep "deltasmaxxx?text=" "$NGINX_ROOT/index.html" | head -2
fi

echo ""
echo "8️⃣ Проверка конфигурации Nginx..."
sudo nginx -t

if [ $? -ne 0 ]; then
    echo "❌ Ошибка в конфигурации Nginx!"
    exit 1
fi

echo ""
echo "9️⃣ Перезагрузка Nginx..."
sudo systemctl reload nginx

if [ $? -eq 0 ]; then
    echo "✅ Nginx перезагружен"
else
    echo "⚠️  Попытка перезапуска..."
    sudo systemctl restart nginx
fi

echo ""
echo "🔟 Проверка статуса Nginx..."
sudo systemctl status nginx --no-pager -l | head -3

echo ""
echo "✅ Готово!"
echo ""
echo "📋 Проверьте сайт:"
echo "   https://e-novolunie.ru"
echo ""
echo "💡 Если ссылки не обновились:"
echo "   1. Очистите кэш браузера (Ctrl+Shift+R)"
echo "   2. Проверьте в режиме инкогнито"
echo "   3. Проверьте исходный код страницы (F12 → Elements)"
