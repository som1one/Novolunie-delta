#!/bin/bash

echo "🔧 Исправление проблемы 503 при получении SSL сертификатов"
echo "=========================================================="
echo ""

echo "1️⃣ Проверка DNS записей домена..."
echo "----------------------------------------"
echo "Проверяем, куда указывает домен:"
echo ""
DOMAIN_IP=$(dig +short e-novolunie.ru | tail -1)
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "")

echo "IP домена e-novolunie.ru: $DOMAIN_IP"
echo "IP сервера: $SERVER_IP"
echo ""

if [ -n "$DOMAIN_IP" ] && [ -n "$SERVER_IP" ] && [ "$DOMAIN_IP" != "$SERVER_IP" ]; then
    echo "⚠️  ВНИМАНИЕ: Домен указывает на другой IP!"
    echo "   Домен: $DOMAIN_IP"
    echo "   Сервер: $SERVER_IP"
    echo ""
    echo "Нужно обновить DNS записи домена, чтобы он указывал на IP сервера: $SERVER_IP"
    echo ""
    read -p "Продолжить всё равно? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo ""

echo "2️⃣ Проверка доступности порта 80 снаружи..."
echo "----------------------------------------"
if [ -n "$SERVER_IP" ]; then
    echo "Проверяем доступность HTTP снаружи..."
    HTTP_EXT_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://$SERVER_IP 2>&1)
    if [ "$HTTP_EXT_CODE" = "200" ] || [ "$HTTP_EXT_CODE" = "301" ] || [ "$HTTP_EXT_CODE" = "302" ]; then
        echo "✅ HTTP доступен снаружи (код: $HTTP_EXT_CODE)"
    else
        echo "❌ HTTP недоступен снаружи (код: $HTTP_EXT_CODE)"
        echo ""
        echo "Проверьте файрвол провайдера в панели управления!"
    fi
else
    echo "⚠️  Не удалось определить IP сервера"
fi
echo ""

echo "3️⃣ Временное отключение редиректа на HTTPS..."
echo "----------------------------------------"
echo "Создаём временную конфигурацию без редиректа для получения сертификатов..."
echo ""

# Создаём временную конфигурацию только с HTTP (без редиректа)
sudo tee /etc/nginx/sites-available/e-novolunie.ru > /dev/null << 'EOF'
# HTTP сервер (временно без редиректа для получения сертификатов)
server {
    listen 80;
    listen [::]:80;
    server_name e-novolunie.ru www.e-novolunie.ru;

    root /var/www/e-novolunie.ru;
    index index.html;

    # Логи
    access_log /var/log/nginx/e-novolunie-access.log;
    error_log /var/log/nginx/e-novolunie-error.log;

    # Разрешаем доступ к ACME challenge для certbot
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files $uri =404;
    }

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

# Создаём директорию для ACME challenge
sudo mkdir -p /var/www/certbot
sudo chown -R www-data:www-data /var/www/certbot

# Активируем конфигурацию
sudo ln -sf /etc/nginx/sites-available/e-novolunie.ru /etc/nginx/sites-enabled/

echo "✅ Временная конфигурация создана"
echo ""

echo "4️⃣ Проверка конфигурации Nginx..."
echo "----------------------------------------"
if sudo nginx -t; then
    echo "✅ Конфигурация корректна"
else
    echo "❌ Ошибка в конфигурации"
    exit 1
fi
echo ""

echo "5️⃣ Перезапуск Nginx..."
echo "----------------------------------------"
sudo systemctl reload nginx
echo "✅ Nginx перезагружен"
echo ""

echo "6️⃣ Проверка доступности ACME challenge..."
echo "----------------------------------------"
TEST_CHALLENGE="/var/www/certbot/test.txt"
echo "test" | sudo tee "$TEST_CHALLENGE" > /dev/null
TEST_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost/.well-known/acme-challenge/test.txt 2>&1)
sudo rm -f "$TEST_CHALLENGE"

if [ "$TEST_CODE" = "200" ]; then
    echo "✅ ACME challenge доступен (код: $TEST_CODE)"
else
    echo "⚠️  ACME challenge вернул код: $TEST_CODE"
fi
echo ""

echo "7️⃣ Получение SSL сертификатов..."
echo "----------------------------------------"
echo "Используем webroot метод вместо nginx плагина..."
echo ""

read -p "Введите email для уведомлений (или нажмите Enter для пропуска): " EMAIL

if [ -z "$EMAIL" ]; then
    sudo certbot certonly --webroot -w /var/www/certbot -d e-novolunie.ru -d www.e-novolunie.ru --register-unsafely-without-email --agree-tos --non-interactive
else
    sudo certbot certonly --webroot -w /var/www/certbot -d e-novolunie.ru -d www.e-novolunie.ru --email "$EMAIL" --agree-tos --non-interactive
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Сертификаты получены!"
    CERT_PATH="/etc/letsencrypt/live/e-novolunie.ru"
    
    echo ""
    echo "8️⃣ Настройка HTTPS конфигурации..."
    echo "----------------------------------------"
    
    # Создаём полную конфигурацию с HTTPS
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
    echo "9️⃣ Проверка HTTPS..."
    echo "----------------------------------------"
    HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 -k https://localhost 2>&1)
    if [ "$HTTPS_CODE" = "200" ]; then
        echo "✅ HTTPS работает (код: $HTTPS_CODE)"
    else
        echo "⚠️  HTTPS вернул код: $HTTPS_CODE"
    fi
    echo ""
    
    echo "=========================================================="
    echo "✅ SSL сертификаты получены и HTTPS настроен!"
    echo ""
    echo "🌐 Проверьте сайт:"
    echo "  https://e-novolunie.ru"
    echo "  https://www.e-novolunie.ru"
    echo ""
    echo "📝 Сертификаты будут автоматически обновляться"
    echo "   Проверка обновления: sudo certbot renew --dry-run"
else
    echo ""
    echo "❌ Ошибка при получении сертификатов"
    echo ""
    echo "Возможные причины:"
    echo "  1. Домен не указывает на этот сервер (DNS)"
    echo "  2. Порты 80 и 443 закрыты файрволом провайдера"
    echo "  3. Балансировщик нагрузки блокирует запросы"
    echo ""
    echo "Проверьте:"
    echo "  - DNS записи домена (должны указывать на IP: $SERVER_IP)"
    echo "  - Файрвол провайдера в панели управления"
    echo "  - Настройки балансировщика нагрузки"
    exit 1
fi
