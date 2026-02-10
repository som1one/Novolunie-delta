#!/bin/bash

echo "🔍 Проверка статуса Nginx и сайта"
echo "=================================="
echo ""

echo "1️⃣ Статус Nginx..."
echo "----------------------------------------"
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx запущен"
    systemctl status nginx --no-pager | head -10
else
    echo "❌ Nginx не запущен"
    echo ""
    echo "Запускаем Nginx..."
    sudo systemctl start nginx
    sudo systemctl status nginx --no-pager | head -10
fi
echo ""

echo "2️⃣ Проверка конфигурации Nginx..."
echo "----------------------------------------"
if sudo nginx -t; then
    echo "✅ Конфигурация Nginx корректна"
else
    echo "❌ Ошибка в конфигурации Nginx!"
    echo ""
    echo "Проверьте ошибки выше"
    exit 1
fi
echo ""

echo "3️⃣ Проверка портов..."
echo "----------------------------------------"
echo "Порт 80 (HTTP):"
if sudo netstat -tlnp | grep -q ":80 "; then
    echo "✅ Порт 80 слушается"
    sudo netstat -tlnp | grep ":80 "
else
    echo "❌ Порт 80 не слушается"
fi
echo ""

echo "Порт 443 (HTTPS):"
if sudo netstat -tlnp | grep -q ":443 "; then
    echo "✅ Порт 443 слушается"
    sudo netstat -tlnp | grep ":443 "
else
    echo "❌ Порт 443 не слушается"
fi
echo ""

echo "4️⃣ Проверка доступности HTTP..."
echo "----------------------------------------"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost 2>&1)
if [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "✅ HTTP работает (код: $HTTP_CODE - редирект на HTTPS)"
elif [ "$HTTP_CODE" = "200" ]; then
    echo "✅ HTTP работает (код: $HTTP_CODE)"
else
    echo "⚠️  HTTP вернул код: $HTTP_CODE"
fi
echo ""

echo "5️⃣ Проверка доступности HTTPS..."
echo "----------------------------------------"
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 -k https://localhost 2>&1)
if [ "$HTTPS_CODE" = "200" ]; then
    echo "✅ HTTPS работает (код: $HTTPS_CODE)"
else
    echo "⚠️  HTTPS вернул код: $HTTPS_CODE"
fi
echo ""

echo "6️⃣ Проверка конфигурации сайта..."
echo "----------------------------------------"
if [ -f "/etc/nginx/sites-enabled/e-novolunie.ru" ]; then
    echo "✅ Конфигурация сайта найдена"
    echo ""
    echo "Проверка SSL настроек:"
    if sudo grep -q "ssl_certificate" /etc/nginx/sites-enabled/e-novolunie.ru; then
        echo "✅ SSL настроен"
        sudo grep "ssl_certificate" /etc/nginx/sites-enabled/e-novolunie.ru | head -2
    else
        echo "⚠️  SSL не настроен (только HTTP)"
    fi
else
    echo "❌ Конфигурация сайта не найдена"
fi
echo ""

echo "7️⃣ Проверка файлов сайта..."
echo "----------------------------------------"
if [ -f "/var/www/e-novolunie.ru/index.html" ]; then
    echo "✅ Файлы сайта найдены в /var/www/e-novolunie.ru/"
    ls -la /var/www/e-novolunie.ru/ | head -10
else
    echo "❌ Файлы сайта не найдены в /var/www/e-novolunie.ru/"
fi
echo ""

echo "8️⃣ Проверка снаружи (если доступен IP)..."
echo "----------------------------------------"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "")
if [ -n "$SERVER_IP" ]; then
    echo "IP сервера: $SERVER_IP"
    echo ""
    echo "HTTP:"
    HTTP_EXT_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://$SERVER_IP 2>&1)
    if [ "$HTTP_EXT_CODE" = "301" ] || [ "$HTTP_EXT_CODE" = "302" ] || [ "$HTTP_EXT_CODE" = "200" ]; then
        echo "✅ HTTP доступен снаружи (код: $HTTP_EXT_CODE)"
    else
        echo "⚠️  HTTP недоступен снаружи (код: $HTTP_EXT_CODE)"
    fi
    echo ""
    echo "HTTPS:"
    HTTPS_EXT_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 -k https://$SERVER_IP 2>&1)
    if [ "$HTTPS_EXT_CODE" = "200" ]; then
        echo "✅ HTTPS доступен снаружи (код: $HTTPS_EXT_CODE)"
    else
        echo "⚠️  HTTPS недоступен снаружи (код: $HTTPS_EXT_CODE)"
    fi
else
    echo "⚠️  Не удалось определить IP сервера"
fi
echo ""

echo "=================================="
echo "📋 РЕЗЮМЕ"
echo "=================================="
echo ""
echo "Nginx: $(systemctl is-active nginx 2>/dev/null && echo '✅ Запущен' || echo '❌ Не запущен')"
echo "Порт 80: $(sudo netstat -tlnp 2>/dev/null | grep -q ':80 ' && echo '✅ Открыт' || echo '❌ Закрыт')"
echo "Порт 443: $(sudo netstat -tlnp 2>/dev/null | grep -q ':443 ' && echo '✅ Открыт' || echo '❌ Закрыт')"
echo "HTTP: $(curl -s -o /dev/null -w '%{http_code}' --max-time 2 http://localhost 2>&1)"
echo "HTTPS: $(curl -s -o /dev/null -w '%{http_code}' --max-time 2 -k https://localhost 2>&1)"
echo ""
echo "🌐 Проверьте сайт:"
echo "  http://e-novolunie.ru"
echo "  https://e-novolunie.ru"
echo ""
echo "📝 Полезные команды:"
echo "  sudo systemctl restart nginx    # Перезапуск Nginx"
echo "  sudo nginx -t                   # Проверка конфигурации"
echo "  sudo tail -f /var/log/nginx/e-novolunie-error.log   # Логи ошибок"