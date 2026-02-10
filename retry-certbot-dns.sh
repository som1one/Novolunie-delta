#!/bin/bash

echo "🔄 Повторная попытка получения SSL сертификатов через DNS challenge"
echo "====================================================================="
echo ""

echo "1️⃣ Проверка DNS TXT записей..."
echo "----------------------------------------"
echo "Проверяем _acme-challenge.e-novolunie.ru:"
TXT1=$(dig +short TXT _acme-challenge.e-novolunie.ru 2>/dev/null || echo "")
if [ -n "$TXT1" ]; then
    echo "✅ Найдена: $TXT1"
else
    echo "❌ Не найдена"
fi
echo ""

echo "Проверяем _acme-challenge.www.e-novolunie.ru:"
TXT2=$(dig +short TXT _acme-challenge.www.e-novolunie.ru 2>/dev/null || echo "")
if [ -n "$TXT2" ]; then
    echo "✅ Найдена: $TXT2"
else
    echo "❌ Не найдена"
fi
echo ""

if [ -z "$TXT1" ] || [ -z "$TXT2" ]; then
    echo "⚠️  TXT записи не найдены в DNS!"
    echo ""
    echo "Выполните:"
    echo "  ./check-dns-txt.sh"
    echo ""
    echo "Или добавьте TXT записи вручную в панели управления доменом."
    echo ""
    read -p "Продолжить всё равно? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo ""

echo "2️⃣ Получение сертификатов через DNS challenge..."
echo "----------------------------------------"
read -p "Введите email для уведомлений (или нажмите Enter для пропуска): " EMAIL

if [ -z "$EMAIL" ]; then
    sudo certbot certonly --manual --preferred-challenges dns -d e-novolunie.ru -d www.e-novolunie.ru --register-unsafely-without-email --agree-tos
else
    sudo certbot certonly --manual --preferred-challenges dns -d e-novolunie.ru -d www.e-novolunie.ru --email "$EMAIL" --agree-tos
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Сертификаты получены!"
    
    # Запускаем скрипт настройки HTTPS
    if [ -f "./enable-https-port.sh" ]; then
        echo ""
        echo "3️⃣ Настройка HTTPS..."
        echo "----------------------------------------"
        # Используем только часть скрипта для настройки HTTPS
        CERT_PATH="/etc/letsencrypt/live/e-novolunie.ru"
        
        sudo tee /etc/nginx/sites-available/e-novolunie.ru > /dev/null << EOF
# HTTP сервер - редирект на HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name e-novolunie.ru www.e-novolunie.ru;

    # Разрешаем доступ к ACME challenge для обновления сертификатов
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files \$uri =404;
    }

    # Редирект на HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }
}

# HTTPS сервер
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name e-novolunie.ru www.e-novolunie.ru;

    # SSL сертификаты
    ssl_certificate $CERT_PATH/fullchain.pem;
    ssl_certificate_key $CERT_PATH/privkey.pem;

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

        if [ -f "$CERT_PATH/chain.pem" ]; then
            sudo tee -a /etc/nginx/sites-available/e-novolunie.ru > /dev/null << EOF
    ssl_trusted_certificate $CERT_PATH/chain.pem;
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

        sudo ln -sf /etc/nginx/sites-available/e-novolunie.ru /etc/nginx/sites-enabled/
        
        if sudo nginx -t; then
            sudo systemctl reload nginx
            echo "✅ HTTPS настроен"
        fi
    fi
    
    echo ""
    echo "=========================================="
    echo "✅ SSL сертификаты получены и HTTPS настроен!"
    echo ""
    echo "🌐 Проверьте сайт:"
    echo "  https://e-novolunie.ru"
    echo "  https://www.e-novolunie.ru"
else
    echo ""
    echo "❌ Ошибка при получении сертификатов"
    echo ""
    echo "Убедитесь, что:"
    echo "  1. TXT записи добавлены в DNS"
    echo "  2. Подождали 2-5 минут для распространения DNS"
    echo "  3. Проверили записи: dig TXT _acme-challenge.e-novolunie.ru"
fi
