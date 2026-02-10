#!/bin/bash

echo "🔧 Исправление конфигурации Nginx без SSL"
echo "=========================================="
echo ""

echo "1️⃣ Проверка существующих сертификатов..."
echo "----------------------------------------"
if [ -f "/etc/letsencrypt/live/e-novolunie.ru/fullchain.pem" ]; then
    echo "✅ SSL сертификаты найдены"
    exit 0
else
    echo "❌ SSL сертификаты не найдены"
    echo ""
    echo "Проверяем другие возможные пути:"
    sudo ls -la /etc/letsencrypt/live/ 2>/dev/null || echo "Директория /etc/letsencrypt/live/ не существует"
    echo ""
fi

echo "2️⃣ Создание временной конфигурации без SSL (только HTTP)..."
echo "----------------------------------------"
sudo tee /etc/nginx/sites-available/e-novolunie.ru > /dev/null << 'EOF'
# HTTP сервер (временно без HTTPS)
server {
    listen 80;
    listen [::]:80;
    server_name e-novolunie.ru www.e-novolunie.ru;

    root /var/www/e-novolunie.ru;
    index index.html;

    # Логи
    access_log /var/log/nginx/e-novolunie-access.log;
    error_log /var/log/nginx/e-novolunie-error.log;

    # Отключаем логирование favicon
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    # Основная локация - правильная обработка путей
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Статические файлы с правильными MIME типами
    location ~* \.(jpg|jpeg|png|gif|ico|svg|webp)$ {
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
        access_log off;
        add_header X-Content-Type-Options "nosniff" always;
    }

    # CSS и JS файлы
    location ~* \.(css|js)$ {
        expires 7d;
        add_header Cache-Control "public, max-age=604800";
        add_header X-Content-Type-Options "nosniff" always;
    }

    # Шрифты
    location ~* \.(woff|woff2|ttf|eot|otf)$ {
        expires 1y;
        add_header Cache-Control "public, max-age=31536000, immutable";
        access_log off;
        add_header Access-Control-Allow-Origin "*";
    }

    # Gzip сжатие
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_min_length 1000;
    gzip_types 
        text/plain 
        text/css 
        text/xml 
        text/javascript 
        application/javascript 
        application/xml+rss 
        application/json 
        application/xml
        image/svg+xml
        font/woff
        font/woff2;

    # Обработка ошибок
    error_page 404 /index.html;
    error_page 500 502 503 504 /index.html;

    # Отключаем показ версии Nginx
    server_tokens off;

    # Увеличиваем размер загружаемых файлов (если нужно)
    client_max_body_size 10M;
}
EOF

echo "✅ Временная конфигурация создана (только HTTP)"
echo ""

echo "3️⃣ Проверка конфигурации Nginx..."
echo "----------------------------------------"
if sudo nginx -t; then
    echo "✅ Конфигурация Nginx корректна"
else
    echo "❌ Ошибка в конфигурации Nginx!"
    exit 1
fi
echo ""

echo "4️⃣ Перезапуск Nginx..."
echo "----------------------------------------"
sudo systemctl restart nginx
echo "✅ Nginx перезапущен"
echo ""

echo "5️⃣ Проверка доступности HTTP..."
echo "----------------------------------------"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost 2>&1)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ HTTP работает (код: $HTTP_CODE)"
else
    echo "⚠️  HTTP вернул код: $HTTP_CODE"
fi
echo ""

echo "=========================================="
echo "✅ Конфигурация исправлена!"
echo ""
echo "📝 Следующие шаги для получения SSL:"
echo ""
echo "1. Установите certbot (если не установлен):"
echo "   sudo apt install certbot python3-certbot-nginx -y"
echo ""
echo "2. Получите SSL сертификаты:"
echo "   sudo certbot --nginx -d e-novolunie.ru -d www.e-novolunie.ru"
echo ""
echo "3. Certbot автоматически обновит конфигурацию Nginx с HTTPS"
echo ""
echo "🌐 Сайт доступен по HTTP:"
echo "   http://e-novolunie.ru"
echo "   http://www.e-novolunie.ru"
