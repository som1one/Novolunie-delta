#!/bin/bash

echo "🔒 Настройка порта 443 для HTTPS"
echo "================================"
echo ""

echo "1️⃣ Проверка текущей конфигурации Nginx..."
echo "----------------------------------------"
if [ -f "/etc/nginx/sites-enabled/e-novolunie.ru" ]; then
    echo "Конфигурация найдена"
    echo ""
    echo "Проверка портов:"
    if sudo grep -q "listen 443" /etc/nginx/sites-enabled/e-novolunie.ru; then
        echo "✅ Порт 443 настроен в конфигурации"
        sudo grep "listen" /etc/nginx/sites-enabled/e-novolunie.ru
    else
        echo "❌ Порт 443 не настроен"
    fi
    echo ""
    
    echo "Проверка SSL сертификатов:"
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

echo "2️⃣ Проверка портов на сервере..."
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

echo "3️⃣ Поиск SSL сертификатов..."
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
    echo "Получаем сертификаты через certbot (webroot метод)..."
    echo ""
    
    # Создаём директорию для ACME challenge
    sudo mkdir -p /var/www/certbot
    sudo chown -R www-data:www-data /var/www/certbot
    
    # Убеждаемся, что конфигурация разрешает доступ к ACME challenge
    if ! sudo grep -q "/.well-known/acme-challenge/" /etc/nginx/sites-enabled/e-novolunie.ru 2>/dev/null; then
        echo "Добавляем поддержку ACME challenge в конфигурацию..."
        # Временно добавляем location для ACME challenge перед редиректом
        sudo sed -i '/return 301 https/i\    location /.well-known/acme-challenge/ {\n        root /var/www/certbot;\n        try_files $uri =404;\n    }' /etc/nginx/sites-enabled/e-novolunie.ru 2>/dev/null || {
            echo "Не удалось автоматически добавить, создаём новую конфигурацию..."
        }
    fi
    
    sudo systemctl reload nginx
    
    read -p "Введите email для уведомлений (или нажмите Enter для пропуска): " EMAIL
    
    if [ -z "$EMAIL" ]; then
        sudo certbot certonly --webroot -w /var/www/certbot -d e-novolunie.ru -d www.e-novolunie.ru --register-unsafely-without-email --agree-tos --non-interactive
    else
        sudo certbot certonly --webroot -w /var/www/certbot -d e-novolunie.ru -d www.e-novolunie.ru --email "$EMAIL" --agree-tos --non-interactive
    fi
    
    if [ $? -eq 0 ]; then
        CERT_FOUND="/etc/letsencrypt/live/e-novolunie.ru"
        echo "✅ Сертификаты получены"
    else
        echo "❌ Ошибка при получении сертификатов"
        echo ""
        echo "Попробуйте получить сертификаты вручную:"
        echo "  sudo certbot certonly --webroot -w /var/www/certbot -d e-novolunie.ru -d www.e-novolunie.ru"
        exit 1
    fi
fi
echo ""

echo "4️⃣ Создание конфигурации с HTTPS..."
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

echo "✅ Конфигурация с HTTPS создана"
echo ""

echo "5️⃣ Проверка конфигурации Nginx..."
echo "----------------------------------------"
if sudo nginx -t; then
    echo "✅ Конфигурация корректна"
else
    echo "❌ Ошибка в конфигурации"
    echo ""
    echo "Проверьте ошибки выше"
    exit 1
fi
echo ""

echo "6️⃣ Перезапуск Nginx..."
echo "----------------------------------------"
sudo systemctl reload nginx
echo "✅ Nginx перезагружен"
echo ""

echo "7️⃣ Проверка портов после перезапуска..."
echo "----------------------------------------"
sleep 2
if command -v ss &> /dev/null; then
    echo "Порт 80:"
    sudo ss -tlnp | grep ":80 " || echo "❌ Порт 80 не слушается"
    echo ""
    echo "Порт 443:"
    if sudo ss -tlnp | grep ":443 "; then
        echo "✅ Порт 443 слушается!"
        sudo ss -tlnp | grep ":443 "
    else
        echo "❌ Порт 443 всё ещё не слушается"
        echo ""
        echo "Проверьте логи:"
        echo "  sudo tail -20 /var/log/nginx/e-novolunie-error.log"
        echo "  sudo journalctl -u nginx -n 20"
    fi
else
    echo "Порт 80:"
    sudo netstat -tlnp 2>/dev/null | grep ":80 " || echo "❌ Порт 80 не слушается"
    echo ""
    echo "Порт 443:"
    if sudo netstat -tlnp 2>/dev/null | grep ":443 "; then
        echo "✅ Порт 443 слушается!"
        sudo netstat -tlnp | grep ":443 "
    else
        echo "❌ Порт 443 всё ещё не слушается"
    fi
fi
echo ""

echo "8️⃣ Проверка доступности HTTPS..."
echo "----------------------------------------"
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 -k https://localhost 2>&1)
if [ "$HTTPS_CODE" = "200" ]; then
    echo "✅ HTTPS работает локально (код: $HTTPS_CODE)"
else
    echo "⚠️  HTTPS вернул код: $HTTPS_CODE"
    if [ "$HTTPS_CODE" != "000" ]; then
        echo "   Это означает, что соединение установлено, но есть проблема с ответом"
    else
        echo "   Это означает, что соединение не установлено"
    fi
fi
echo ""

echo "=========================================="
echo "✅ Настройка завершена!"
echo ""
echo "📋 Резюме:"
echo "  - SSL сертификаты: $CERT_FOUND"
echo "  - Порт 80: $(command -v ss &> /dev/null && (sudo ss -tlnp | grep -q ':80 ' && echo '✅ Слушается' || echo '❌ Не слушается') || (sudo netstat -tlnp 2>/dev/null | grep -q ':80 ' && echo '✅ Слушается' || echo '❌ Не слушается'))"
echo "  - Порт 443: $(command -v ss &> /dev/null && (sudo ss -tlnp | grep -q ':443 ' && echo '✅ Слушается' || echo '❌ Не слушается') || (sudo netstat -tlnp 2>/dev/null | grep -q ':443 ' && echo '✅ Слушается' || echo '❌ Не слушается'))"
echo ""
echo "🌐 Проверьте сайт:"
echo "  https://e-novolunie.ru"
echo "  https://www.e-novolunie.ru"
echo ""
echo "📝 Если порт 443 всё ещё не слушается, проверьте:"
echo "  sudo tail -f /var/log/nginx/e-novolunie-error.log"
echo "  sudo journalctl -u nginx -f"
