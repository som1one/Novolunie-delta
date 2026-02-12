#!/bin/bash

# Скрипт для проверки конфигурации Nginx и доступности логотипа

echo "🔍 Проверка Nginx и логотипа"
echo "============================"
echo ""

echo "1️⃣ Проверка конфигурации Nginx..."
sudo nginx -t

if [ $? -ne 0 ]; then
    echo "❌ Ошибка в конфигурации Nginx!"
    echo "Исправьте ошибки перед продолжением"
    exit 1
fi

echo ""
echo "2️⃣ Проверка активной конфигурации Nginx..."
NGINX_CONF=$(sudo nginx -T 2>/dev/null | grep -E "root|location.*assets" | head -10)
if [ -n "$NGINX_CONF" ]; then
    echo "Настройки root и assets:"
    echo "$NGINX_CONF"
else
    echo "⚠️  Не найдены настройки root/assets"
fi

echo ""
echo "3️⃣ Проверка файла на сервере..."
if [ -f "/var/www/html/assets/logo.png" ]; then
    echo "✅ Файл существует: /var/www/html/assets/logo.png"
    ls -lh /var/www/html/assets/logo.png
    
    # Проверка прав доступа
    PERMS=$(stat -c "%a" /var/www/html/assets/logo.png 2>/dev/null || stat -f "%OLp" /var/www/html/assets/logo.png 2>/dev/null)
    OWNER=$(stat -c "%U:%G" /var/www/html/assets/logo.png 2>/dev/null || stat -f "%Su:%Sg" /var/www/html/assets/logo.png 2>/dev/null)
    echo "   Права: $PERMS"
    echo "   Владелец: $OWNER"
else
    echo "❌ Файл НЕ найден: /var/www/html/assets/logo.png"
fi

echo ""
echo "4️⃣ Проверка структуры папок..."
echo "Содержимое /var/www/html/:"
ls -la /var/www/html/ | head -20

echo ""
echo "Содержимое /var/www/html/assets/:"
ls -la /var/www/html/assets/ 2>/dev/null || echo "Папка assets не найдена"

echo ""
echo "5️⃣ Проверка доступности через localhost..."
LOCAL_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://localhost/assets/logo.png" 2>/dev/null || echo "000")
if [ "$LOCAL_CODE" = "200" ]; then
    echo "✅ Логотип доступен через localhost"
else
    echo "❌ Логотип НЕ доступен через localhost (код: $LOCAL_CODE)"
fi

echo ""
echo "6️⃣ Проверка доступности через домен..."
DOMAIN="e-novolunie.ru"
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://${DOMAIN}/assets/logo.png" 2>/dev/null || echo "000")
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://${DOMAIN}/assets/logo.png" 2>/dev/null || echo "000")

if [ "$HTTPS_CODE" = "200" ]; then
    echo "✅ Логотип доступен через HTTPS: https://${DOMAIN}/assets/logo.png"
elif [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Логотип доступен через HTTP: http://${DOMAIN}/assets/logo.png"
    echo "⚠️  Но не через HTTPS (код: $HTTPS_CODE)"
else
    echo "❌ Логотип НЕ доступен через домен"
    echo "   HTTP код: $HTTP_CODE"
    echo "   HTTPS код: $HTTPS_CODE"
fi

echo ""
echo "7️⃣ Проверка конфигурации сайта..."
SITE_CONF=$(ls /etc/nginx/sites-enabled/* 2>/dev/null | head -1)
if [ -n "$SITE_CONF" ]; then
    echo "Конфигурация сайта: $SITE_CONF"
    echo ""
    echo "Настройки root и location:"
    sudo grep -E "^\s*(root|location)" "$SITE_CONF" | head -10
else
    echo "⚠️  Конфигурация сайта не найдена в /etc/nginx/sites-enabled/"
    echo "Проверяем основную конфигурацию..."
    sudo grep -E "^\s*(root|location)" /etc/nginx/nginx.conf | head -10
fi

echo ""
echo "8️⃣ Проверка логов Nginx (последние 5 строк)..."
sudo tail -5 /var/log/nginx/error.log 2>/dev/null || echo "Логи не найдены"

echo ""
echo "✅ Проверка завершена!"
echo ""
echo "📋 Рекомендации:"
if [ "$HTTPS_CODE" != "200" ] && [ "$HTTP_CODE" != "200" ]; then
    echo "1. Проверьте конфигурацию Nginx: sudo nginx -t"
    echo "2. Проверьте, что root указывает на /var/www/html"
    echo "3. Проверьте логи: sudo tail -f /var/log/nginx/error.log"
    echo "4. Проверьте доступность файла: curl -I http://localhost/assets/logo.png"
fi
