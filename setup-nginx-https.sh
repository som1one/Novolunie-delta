#!/bin/bash

echo "🔒 Настройка Nginx с HTTPS"
echo "=========================="
echo ""

echo "1️⃣ Поиск SSL сертификатов..."
echo "----------------------------------------"
echo "Проверяем стандартные пути:"
echo ""

# Проверяем разные возможные пути
CERT_PATHS=(
    "/etc/letsencrypt/live/e-novolunie.ru"
    "/etc/letsencrypt/live/www.e-novolunie.ru"
    "/etc/nginx/ssl"
    "/etc/ssl/certs"
    "/root/ssl"
    "/home/ssl"
)

# Также проверяем все домены в Let's Encrypt
if [ -d "/etc/letsencrypt/live" ]; then
    for domain_dir in /etc/letsencrypt/live/*; do
        if [ -d "$domain_dir" ]; then
            CERT_PATHS+=("$domain_dir")
        fi
    done
fi

FOUND_CERT=""
FOUND_DOMAIN=""

for path in "${CERT_PATHS[@]}"; do
    if [ -f "$path/fullchain.pem" ] && [ -f "$path/privkey.pem" ]; then
        echo "✅ Сертификаты найдены: $path"
        FOUND_CERT="$path"
        FOUND_DOMAIN=$(basename "$path")
        break
    fi
done

# Если не нашли, ищем все домены в Let's Encrypt
if [ -z "$FOUND_CERT" ]; then
    echo "Ищем сертификаты в /etc/letsencrypt/live/..."
    if [ -d "/etc/letsencrypt/live" ]; then
        for domain_dir in /etc/letsencrypt/live/*; do
            if [ -d "$domain_dir" ] && [ -f "$domain_dir/fullchain.pem" ] && [ -f "$domain_dir/privkey.pem" ]; then
                echo "✅ Найдены сертификаты для: $(basename $domain_dir)"
                if [ -z "$FOUND_CERT" ]; then
                    FOUND_CERT="$domain_dir"
                    FOUND_DOMAIN=$(basename "$domain_dir")
                fi
            fi
        done
    fi
fi

if [ -z "$FOUND_CERT" ]; then
    echo "❌ SSL сертификаты не найдены автоматически!"
    echo ""
    echo "Выполните полный поиск:"
    echo "  chmod +x find-ssl-certificates.sh"
    echo "  ./find-ssl-certificates.sh"
    echo ""
    echo "Если сертификаты были получены через панель Timeweb Cloud:"
    echo "1. Войдите в панель управления Timeweb Cloud"
    echo "2. Перейдите: Домены → e-novolunie.ru → SSL"
    echo "3. Проверьте статус SSL сертификата"
    echo "4. Если сертификат активирован, но не на сервере - получите через certbot:"
    echo ""
    echo "   sudo apt install certbot python3-certbot-nginx -y"
    echo "   sudo certbot --nginx -d e-novolunie.ru -d www.e-novolunie.ru"
    echo ""
    echo "Или используйте временную конфигурацию без SSL:"
    echo "  ./fix-nginx-ssl.sh"
    echo ""
    read -p "Продолжить с получением новых сертификатов через certbot? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Устанавливаем certbot..."
        sudo apt update
        sudo apt install certbot python3-certbot-nginx -y
        echo ""
        echo "Получаем SSL сертификаты..."
        sudo certbot --nginx -d e-novolunie.ru -d www.e-novolunie.ru
        echo ""
        echo "✅ Сертификаты получены, certbot автоматически обновил конфигурацию Nginx"
        echo ""
        echo "Проверьте работу:"
        echo "  curl -I https://e-novolunie.ru"
        exit 0
    else
        exit 1
    fi
fi

echo ""
echo "Используем сертификаты из: $FOUND_CERT"
echo "Домен: $FOUND_DOMAIN"
echo ""

echo "2️⃣ Создание конфигурации Nginx с HTTPS..."
echo "----------------------------------------"
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
    ssl_certificate $FOUND_CERT/fullchain.pem;
    ssl_certificate_key $FOUND_CERT/privkey.pem;

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

# Добавляем chain.pem только если он существует
if [ -f "$FOUND_CERT/chain.pem" ]; then
    sudo tee -a /etc/nginx/sites-available/e-novolunie.ru > /dev/null << EOF
    ssl_trusted_certificate $FOUND_CERT/chain.pem;
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

echo "✅ Конфигурация создана с SSL сертификатами"
echo ""

echo "3️⃣ Проверка конфигурации Nginx..."
echo "----------------------------------------"
if sudo nginx -t; then
    echo "✅ Конфигурация Nginx корректна"
else
    echo "❌ Ошибка в конфигурации Nginx!"
    echo ""
    echo "Проверьте конфигурацию вручную:"
    echo "  sudo nginx -t"
    exit 1
fi
echo ""

echo "4️⃣ Перезапуск Nginx..."
echo "----------------------------------------"
sudo systemctl restart nginx
echo "✅ Nginx перезапущен"
echo ""

echo "5️⃣ Проверка доступности..."
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
    echo "  sudo tail -f /var/log/nginx/e-novolunie-error.log"
fi
echo ""

echo "=========================================="
echo "✅ Настройка HTTPS завершена!"
echo ""
echo "📋 Использованы сертификаты:"
echo "  Путь: $FOUND_CERT"
echo "  Домен: $FOUND_DOMAIN"
echo ""
echo "🌐 Проверьте сайт:"
echo "  https://e-novolunie.ru"
echo "  https://www.e-novolunie.ru"
echo ""
echo "📝 Полезные команды:"
echo "  sudo systemctl status nginx"
echo "  sudo nginx -t"
echo "  sudo tail -f /var/log/nginx/e-novolunie-error.log"
