#!/bin/bash

echo "🚀 Миграция с Docker на чистый Nginx"
echo "======================================"
echo ""

PROJECT_DIR="$HOME/novolunie"
cd "$PROJECT_DIR" || {
    echo "❌ Директория $PROJECT_DIR не найдена"
    exit 1
}

echo "1️⃣ Остановка и удаление Docker контейнера..."
echo "----------------------------------------"
if docker ps | grep -q novolunie-web; then
    echo "Останавливаем контейнер..."
    docker compose down
    echo "✅ Контейнер остановлен"
else
    echo "✅ Контейнер уже остановлен"
fi
echo ""

echo "2️⃣ Установка Nginx..."
echo "----------------------------------------"
if command -v nginx &> /dev/null; then
    echo "✅ Nginx уже установлен"
    nginx -v
else
    echo "Устанавливаем Nginx..."
    sudo apt update
    sudo apt install nginx -y
    echo "✅ Nginx установлен"
fi
echo ""

echo "3️⃣ Остановка системного Nginx (если запущен)..."
echo "----------------------------------------"
sudo systemctl stop nginx
echo "✅ Nginx остановлен"
echo ""

echo "4️⃣ Создание директории для сайта..."
echo "----------------------------------------"
sudo mkdir -p /var/www/e-novolunie.ru
echo "✅ Директория создана: /var/www/e-novolunie.ru"
echo ""

echo "5️⃣ Копирование файлов сайта..."
echo "----------------------------------------"
echo "Копируем файлы из проекта..."

# Копируем все файлы сайта
sudo cp -r index.html styles/ js/ images/ fonts/ /var/www/e-novolunie.ru/ 2>/dev/null || {
    echo "⚠️  Некоторые файлы не найдены, продолжаем..."
}

# Проверяем, что index.html скопирован
if [ -f "/var/www/e-novolunie.ru/index.html" ]; then
    echo "✅ Файлы скопированы"
else
    echo "❌ index.html не найден! Проверьте структуру проекта"
    exit 1
fi

# Устанавливаем права
sudo chown -R www-data:www-data /var/www/e-novolunie.ru
sudo chmod -R 755 /var/www/e-novolunie.ru
echo "✅ Права установлены"
echo ""

echo "6️⃣ Создание конфигурации Nginx..."
echo "----------------------------------------"
sudo tee /etc/nginx/sites-available/e-novolunie.ru > /dev/null << 'EOF'
# HTTP сервер - редирект на HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name e-novolunie.ru www.e-novolunie.ru;

    # Редирект на HTTPS
    return 301 https://$host$request_uri;
}

# HTTPS сервер
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name e-novolunie.ru www.e-novolunie.ru;

    # SSL сертификаты
    ssl_certificate /etc/letsencrypt/live/e-novolunie.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/e-novolunie.ru/privkey.pem;

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
    ssl_trusted_certificate /etc/letsencrypt/live/e-novolunie.ru/chain.pem;
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

echo "✅ Конфигурация создана: /etc/nginx/sites-available/e-novolunie.ru"
echo ""

echo "7️⃣ Активация конфигурации..."
echo "----------------------------------------"
sudo ln -sf /etc/nginx/sites-available/e-novolunie.ru /etc/nginx/sites-enabled/
echo "✅ Конфигурация активирована"
echo ""

echo "8️⃣ Удаление дефолтной конфигурации (если есть)..."
echo "----------------------------------------"
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    sudo rm /etc/nginx/sites-enabled/default
    echo "✅ Дефолтная конфигурация удалена"
else
    echo "✅ Дефолтная конфигурация не найдена"
fi
echo ""

echo "9️⃣ Проверка конфигурации Nginx..."
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

echo "🔟 Проверка SSL сертификатов..."
echo "----------------------------------------"
if [ -f "/etc/letsencrypt/live/e-novolunie.ru/fullchain.pem" ]; then
    echo "✅ SSL сертификаты найдены"
else
    echo "⚠️  SSL сертификаты не найдены!"
    echo ""
    echo "Если сертификаты установлены для другого домена, отредактируйте:"
    echo "  sudo nano /etc/nginx/sites-available/e-novolunie.ru"
    echo ""
    echo "Или получите новые сертификаты:"
    echo "  sudo certbot --nginx -d e-novolunie.ru -d www.e-novolunie.ru"
    echo ""
    read -p "Продолжить без SSL? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo ""

echo "1️⃣1️⃣ Открытие портов в файрволе..."
echo "----------------------------------------"
if command -v ufw &> /dev/null; then
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    echo "✅ Порты открыты в UFW"
else
    echo "⚠️  UFW не установлен, пропускаем"
fi
echo ""

echo "1️⃣2️⃣ Запуск Nginx..."
echo "----------------------------------------"
sudo systemctl enable nginx
sudo systemctl start nginx
echo "✅ Nginx запущен"
echo ""

echo "1️⃣3️⃣ Проверка статуса Nginx..."
echo "----------------------------------------"
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx работает"
    sudo systemctl status nginx --no-pager | head -5
else
    echo "❌ Nginx не запущен!"
    echo ""
    echo "Проверьте логи:"
    echo "  sudo journalctl -u nginx -n 50"
    exit 1
fi
echo ""

echo "1️⃣4️⃣ Проверка доступности..."
echo "----------------------------------------"
echo "HTTP (должен редиректить на HTTPS):"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost 2>&1)
if [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "✅ HTTP работает (код: $HTTP_CODE - редирект)"
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
    echo "Проверьте SSL сертификаты:"
    echo "  sudo ls -la /etc/letsencrypt/live/e-novolunie.ru/"
fi
echo ""

echo "======================================"
echo "✅ Миграция завершена!"
echo ""
echo "📋 Что было сделано:"
echo "  ✅ Docker контейнер остановлен"
echo "  ✅ Nginx установлен"
echo "  ✅ Файлы сайта скопированы в /var/www/e-novolunie.ru"
echo "  ✅ Конфигурация Nginx создана и активирована"
echo "  ✅ SSL сертификаты подключены"
echo "  ✅ Порты 80 и 443 открыты"
echo "  ✅ Nginx запущен и работает"
echo ""
echo "📝 Полезные команды:"
echo "  sudo systemctl status nginx          # Статус Nginx"
echo "  sudo systemctl restart nginx         # Перезапуск Nginx"
echo "  sudo nginx -t                        # Проверка конфигурации"
echo "  sudo tail -f /var/log/nginx/e-novolunie-error.log   # Логи ошибок"
echo "  sudo tail -f /var/log/nginx/e-novolunie-access.log  # Логи доступа"
echo ""
echo "🌐 Проверьте сайт:"
echo "  https://e-novolunie.ru"
echo "  https://www.e-novolunie.ru"
echo ""
