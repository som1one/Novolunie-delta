#!/bin/bash

echo "🔒 Получение SSL сертификатов через DNS challenge"
echo "=================================================="
echo ""

echo "DNS challenge не требует доступа к серверу через HTTP,"
echo "поэтому работает даже если балансировщик блокирует запросы."
echo ""

echo "1️⃣ Установка certbot (если не установлен)..."
echo "----------------------------------------"
if ! command -v certbot &> /dev/null; then
    sudo apt update
    sudo apt install certbot -y
    echo "✅ Certbot установлен"
else
    echo "✅ Certbot уже установлен"
fi
echo ""

echo "2️⃣ Получение сертификатов через DNS challenge..."
echo "----------------------------------------"
echo ""
echo "⚠️  ВНИМАНИЕ: Для DNS challenge нужно добавить TXT записи в DNS."
echo "   Certbot покажет, какие записи нужно добавить."
echo ""
echo "Этот метод работает так:"
echo "  1. Certbot сгенерирует TXT записи"
echo "  2. Вы добавите их в DNS (панель управления доменом)"
echo "  3. Certbot проверит записи и выдаст сертификат"
echo ""

read -p "Продолжить с DNS challenge? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Отменено"
    exit 0
fi

read -p "Введите email для уведомлений (или нажмите Enter для пропуска): " EMAIL

if [ -z "$EMAIL" ]; then
    echo ""
    echo "Запускаем certbot с DNS challenge (manual mode)..."
    echo ""
    echo "Certbot попросит добавить TXT записи в DNS."
    echo "После добавления записей нажмите Enter в certbot."
    echo ""
    sudo certbot certonly --manual --preferred-challenges dns -d e-novolunie.ru -d www.e-novolunie.ru --register-unsafely-without-email --agree-tos
else
    echo ""
    echo "Запускаем certbot с DNS challenge (manual mode)..."
    echo ""
    echo "Certbot попросит добавить TXT записи в DNS."
    echo "После добавления записей нажмите Enter в certbot."
    echo ""
    sudo certbot certonly --manual --preferred-challenges dns -d e-novolunie.ru -d www.e-novolunie.ru --email "$EMAIL" --agree-tos
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Сертификаты получены!"
    CERT_PATH="/etc/letsencrypt/live/e-novolunie.ru"
    
    echo ""
    echo "3️⃣ Настройка Nginx с HTTPS..."
    echo "----------------------------------------"
    
    # Создаём конфигурацию с HTTPS
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
    echo "✅ Nginx перезагружен"
    
    echo ""
    echo "4️⃣ Проверка порта 443..."
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
    
    echo "5️⃣ Проверка HTTPS..."
    echo "----------------------------------------"
    HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 -k https://localhost 2>&1)
    if [ "$HTTPS_CODE" = "200" ]; then
        echo "✅ HTTPS работает (код: $HTTPS_CODE)"
    else
        echo "⚠️  HTTPS вернул код: $HTTPS_CODE"
    fi
    echo ""
    
    echo "=================================================="
    echo "✅ SSL сертификаты получены и HTTPS настроен!"
    echo ""
    echo "🌐 Проверьте сайт:"
    echo "  https://e-novolunie.ru"
    echo "  https://www.e-novolunie.ru"
    echo ""
    echo "📝 Сертификаты будут автоматически обновляться"
    echo "   Для обновления используйте DNS challenge:"
    echo "   sudo certbot renew --manual --preferred-challenges dns"
else
    echo ""
    echo "❌ Ошибка при получении сертификатов"
    echo ""
    echo "Убедитесь, что:"
    echo "  1. Добавили TXT записи в DNS (как показал certbot)"
    echo "  2. Подождали несколько минут для распространения DNS"
    echo "  3. Нажали Enter в certbot после добавления записей"
fi
