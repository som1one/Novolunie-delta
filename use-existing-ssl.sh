#!/bin/bash

echo "🔍 Проверка существующих SSL сертификатов"
echo "=========================================="
echo ""

echo "1️⃣ Поиск существующих сертификатов..."
echo "----------------------------------------"
CERT_FOUND=""

# Проверяем стандартные пути
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
    echo "❌ Сертификаты не найдены"
    echo ""
    echo "Попробуем получить новые через DNS challenge..."
    echo ""
    read -p "Продолжить с DNS challenge? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    
    # Используем DNS challenge
    read -p "Введите email для уведомлений (или нажмите Enter для пропуска): " EMAIL
    
    if [ -z "$EMAIL" ]; then
        sudo certbot certonly --manual --preferred-challenges dns -d e-novolunie.ru -d www.e-novolunie.ru --register-unsafely-without-email --agree-tos
    else
        sudo certbot certonly --manual --preferred-challenges dns -d e-novolunie.ru -d www.e-novolunie.ru --email "$EMAIL" --agree-tos
    fi
    
    if [ $? -eq 0 ]; then
        CERT_FOUND="/etc/letsencrypt/live/e-novolunie.ru"
        echo "✅ Сертификаты получены"
    else
        echo "❌ Ошибка при получении сертификатов"
        exit 1
    fi
else
    echo ""
    echo "Проверяем срок действия сертификатов..."
    if [ -f "$CERT_FOUND/fullchain.pem" ]; then
        EXPIRY_DATE=$(sudo openssl x509 -enddate -noout -in "$CERT_FOUND/fullchain.pem" 2>/dev/null | cut -d= -f2)
        echo "Срок действия: $EXPIRY_DATE"
    fi
fi
echo ""

echo "2️⃣ Настройка Nginx с существующими сертификатами..."
echo "----------------------------------------"
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

# Проверяем конфигурацию
if sudo nginx -t; then
    echo "✅ Конфигурация с HTTPS создана"
else
    echo "❌ Ошибка в конфигурации"
    exit 1
fi

# Перезагружаем Nginx
sudo systemctl reload nginx
echo "✅ Nginx перезагружен с HTTPS"
echo ""

echo "3️⃣ Проверка порта 443..."
echo "----------------------------------------"
sleep 2
if command -v ss &> /dev/null; then
    if sudo ss -tlnp | grep ":443 "; then
        echo "✅ Порт 443 слушается!"
        sudo ss -tlnp | grep ":443 "
    else
        echo "❌ Порт 443 не слушается"
    fi
else
    if sudo netstat -tlnp 2>/dev/null | grep ":443 "; then
        echo "✅ Порт 443 слушается!"
        sudo netstat -tlnp | grep ":443 "
    else
        echo "❌ Порт 443 не слушается"
    fi
fi
echo ""

echo "4️⃣ Проверка HTTPS..."
echo "----------------------------------------"
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 -k https://localhost 2>&1)
if [ "$HTTPS_CODE" = "200" ]; then
    echo "✅ HTTPS работает (код: $HTTPS_CODE)"
else
    echo "⚠️  HTTPS вернул код: $HTTPS_CODE"
fi
echo ""

echo "=========================================="
echo "✅ HTTPS настроен!"
echo ""
echo "📋 Использованы сертификаты: $CERT_FOUND"
echo ""
echo "🌐 Проверьте сайт:"
echo "  https://e-novolunie.ru"
echo "  https://www.e-novolunie.ru"
echo ""
echo "📝 Для обновления сертификатов (когда истечёт срок):"
echo "   sudo certbot renew --manual --preferred-challenges dns"
echo ""
echo "⚠️  ВАЖНО: Если сертификатов не было, они были получены через DNS challenge."
echo "   При обновлении нужно будет снова добавить TXT записи в DNS."
