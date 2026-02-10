#!/bin/bash

echo "🔧 Исправление проблемы с HTTPS"
echo "================================"
echo ""

echo "1️⃣ Проверка текущей конфигурации..."
echo "----------------------------------------"
if [ -f "/etc/nginx/sites-enabled/e-novolunie.ru" ]; then
    echo "Конфигурация найдена"
    echo ""
    echo "Проверка SSL:"
    if sudo grep -q "listen 443" /etc/nginx/sites-enabled/e-novolunie.ru; then
        echo "✅ Порт 443 настроен"
    else
        echo "❌ Порт 443 не настроен"
    fi
    
    if sudo grep -q "ssl_certificate" /etc/nginx/sites-enabled/e-novolunie.ru; then
        echo "✅ SSL сертификаты указаны"
        sudo grep "ssl_certificate" /etc/nginx/sites-enabled/e-novolunie.ru | head -2
    else
        echo "❌ SSL сертификаты не указаны"
    fi
else
    echo "❌ Конфигурация не найдена"
fi
echo ""

echo "2️⃣ Проверка портов..."
echo "----------------------------------------"
if command -v ss &> /dev/null; then
    echo "Порт 80:"
    sudo ss -tlnp | grep ":80 " || echo "❌ Порт 80 не слушается"
    echo ""
    echo "Порт 443:"
    sudo ss -tlnp | grep ":443 " || echo "❌ Порт 443 не слушается"
else
    echo "Порт 80:"
    sudo netstat -tlnp 2>/dev/null | grep ":80 " || echo "❌ Порт 80 не слушается"
    echo ""
    echo "Порт 443:"
    sudo netstat -tlnp 2>/dev/null | grep ":443 " || echo "❌ Порт 443 не слушается"
fi
echo ""

echo "3️⃣ Проверка SSL сертификатов..."
echo "----------------------------------------"
CERT_FOUND=""
if [ -f "/etc/letsencrypt/live/e-novolunie.ru/fullchain.pem" ]; then
    CERT_FOUND="/etc/letsencrypt/live/e-novolunie.ru"
    echo "✅ Сертификаты найдены: $CERT_FOUND"
elif [ -d "/etc/letsencrypt/live" ]; then
    for domain_dir in /etc/letsencrypt/live/*; do
        if [ -d "$domain_dir" ] && [ -f "$domain_dir/fullchain.pem" ]; then
            CERT_FOUND="$domain_dir"
            echo "✅ Сертификаты найдены: $CERT_FOUND"
            break
        fi
    done
fi

if [ -z "$CERT_FOUND" ]; then
    echo "❌ SSL сертификаты не найдены"
    echo ""
    echo "Получаем сертификаты через certbot..."
    echo ""
    read -p "Введите email для уведомлений (или нажмите Enter для пропуска): " EMAIL
    
    if [ -z "$EMAIL" ]; then
        sudo certbot --nginx -d e-novolunie.ru -d www.e-novolunie.ru --register-unsafely-without-email --agree-tos --non-interactive
    else
        sudo certbot --nginx -d e-novolunie.ru -d www.e-novolunie.ru --email "$EMAIL" --agree-tos --non-interactive
    fi
    
    if [ $? -eq 0 ]; then
        echo "✅ Сертификаты получены"
        CERT_FOUND="/etc/letsencrypt/live/e-novolunie.ru"
    else
        echo "❌ Ошибка при получении сертификатов"
        exit 1
    fi
fi
echo ""

echo "4️⃣ Проверка конфигурации Nginx..."
echo "----------------------------------------"
if sudo nginx -t; then
    echo "✅ Конфигурация корректна"
else
    echo "❌ Ошибка в конфигурации"
    echo ""
    echo "Исправляем конфигурацию..."
    
    # Создаём конфигурацию с HTTPS
    sudo tee /etc/nginx/sites-available/e-novolunie.ru > /dev/null << EOF
# HTTP сервер - редирект на HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name e-novolunie.ru www.e-novolunie.ru;

    # Редирект на HTTPS
    return 301 https://\$host\$request_uri;
}

# HTTPS сервер
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name e-novolunie.ru www.e-novolunie.ru;

    # SSL сертификаты
    ssl_certificate $CERT_FOUND/fullchain.pem;
    ssl_certificate_key $CERT_FOUND/privkey.pem;

    # SSL настройки
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;

    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;
EOF

    if [ -f "$CERT_FOUND/chain.pem" ]; then
        sudo tee -a /etc/nginx/sites-available/e-novolunie.ru > /dev/null << EOF
    ssl_trusted_certificate $CERT_FOUND/chain.pem;
EOF
    fi

    sudo tee -a /etc/nginx/sites-available/e-novolunie.ru > /dev/null << 'EOF'
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;

    # Безопасность
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

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

    # Активируем конфигурацию
    sudo ln -sf /etc/nginx/sites-available/e-novolunie.ru /etc/nginx/sites-enabled/
    
    # Проверяем снова
    if sudo nginx -t; then
        echo "✅ Конфигурация исправлена"
    else
        echo "❌ Ошибка в конфигурации после исправления"
        exit 1
    fi
fi
echo ""

echo "5️⃣ Перезапуск Nginx..."
echo "----------------------------------------"
sudo systemctl reload nginx
echo "✅ Nginx перезагружен"
echo ""

echo "6️⃣ Проверка доступности..."
echo "----------------------------------------"
echo "HTTP (должен редиректить на HTTPS):"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost 2>&1)
if [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "✅ HTTP работает (код: $HTTP_CODE - редирект на HTTPS)"
else
    echo "⚠️  HTTP вернул код: $HTTP_CODE"
fi
echo ""

echo "HTTPS:"
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 -k https://localhost 2>&1)
if [ "$HTTPS_CODE" = "200" ]; then
    echo "✅ HTTPS работает (код: $HTTPS_CODE)"
else
    echo "⚠️  HTTPS вернул код: $HTTPS_CODE"
    echo ""
    echo "Проверьте логи:"
    echo "  sudo tail -20 /var/log/nginx/e-novolunie-error.log"
fi
echo ""

echo "=========================================="
echo "✅ Исправление завершено!"
echo ""
echo "🌐 Проверьте сайт:"
echo "  https://e-novolunie.ru"
echo "  https://www.e-novolunie.ru"
echo ""
echo "📝 Если HTTPS всё ещё не работает, проверьте:"
echo "  sudo tail -f /var/log/nginx/e-novolunie-error.log"
