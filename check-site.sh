#!/bin/bash

# Скрипт для проверки доступности сайта

SERVER_IP="85.239.44.197"
SERVER_URL="http://${SERVER_IP}"

echo "🔍 Проверка доступности сайта Novolunie"
echo ""

# Проверка доступности основного URL
echo "1. Проверка основного URL..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${SERVER_URL}")
if [ "$HTTP_CODE" -eq 200 ]; then
    echo "   ✅ HTTP $HTTP_CODE - Сайт доступен"
else
    echo "   ❌ HTTP $HTTP_CODE - Проблема с доступностью"
fi

# Проверка CSS
echo ""
echo "2. Проверка CSS файла..."
CSS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${SERVER_URL}/styles/main.css")
if [ "$CSS_CODE" -eq 200 ]; then
    echo "   ✅ CSS загружается (HTTP $CSS_CODE)"
else
    echo "   ❌ CSS не загружается (HTTP $CSS_CODE)"
fi

# Проверка JS
echo ""
echo "3. Проверка JS файла..."
JS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${SERVER_URL}/js/main.js")
if [ "$JS_CODE" -eq 200 ]; then
    echo "   ✅ JS загружается (HTTP $JS_CODE)"
else
    echo "   ❌ JS не загружается (HTTP $JS_CODE)"
fi

# Проверка логотипа
echo ""
echo "4. Проверка изображения..."
IMG_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${SERVER_URL}/assets/logo.png")
if [ "$IMG_CODE" -eq 200 ]; then
    echo "   ✅ Изображение загружается (HTTP $IMG_CODE)"
else
    echo "   ❌ Изображение не загружается (HTTP $IMG_CODE)"
fi

# Проверка времени ответа
echo ""
echo "5. Проверка времени ответа..."
RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" --max-time 10 "${SERVER_URL}")
echo "   ⏱️  Время ответа: ${RESPONSE_TIME} секунд"

# Проверка заголовков
echo ""
echo "6. Проверка заголовков..."
echo "   Content-Type:"
curl -s -I "${SERVER_URL}" | grep -i "content-type" || echo "   ⚠️  Content-Type не найден"

echo ""
echo "   Cache-Control:"
curl -s -I "${SERVER_URL}/styles/main.css" | grep -i "cache-control" || echo "   ⚠️  Cache-Control не найден"

echo ""
echo "✅ Проверка завершена"
echo ""
echo "Для детальной диагностики на сервере выполните:"
echo "  docker compose logs -f"
echo "  docker exec novolunie-web tail -f /var/log/nginx/novolunie-error.log"
