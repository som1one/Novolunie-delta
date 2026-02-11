#!/bin/bash

echo "🔒 Установка SSL сертификата через DNS challenge"
echo "=================================================="
echo ""
echo "Этот метод НЕ требует изменения A-записи"
echo "и работает даже с балансировщиком."
echo ""

# Проверка, что скрипт запущен от root или с sudo
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  Запустите скрипт с sudo:"
    echo "   sudo ./install-ssl-dns.sh"
    exit 1
fi

echo "1️⃣ Установка certbot (если не установлен)..."
echo "----------------------------------------"
if ! command -v certbot &> /dev/null; then
    apt update
    apt install certbot -y
    echo "✅ Certbot установлен"
else
    echo "✅ Certbot уже установлен"
fi
echo ""

echo "2️⃣ Получение сертификатов через DNS challenge..."
echo "----------------------------------------"
echo ""
echo "⚠️  ВНИМАНИЕ: Certbot попросит добавить TXT записи в DNS."
echo "   После добавления записей подождите 2-5 минут"
echo "   и нажмите Enter в certbot."
echo ""

read -p "Введите email для уведомлений (или нажмите Enter для пропуска): " EMAIL

if [ -z "$EMAIL" ]; then
    certbot certonly --manual --preferred-challenges dns \
      -d e-novolunie.ru -d www.e-novolunie.ru \
      --register-unsafely-without-email --agree-tos
else
    certbot certonly --manual --preferred-challenges dns \
      -d e-novolunie.ru -d www.e-novolunie.ru \
      --email "$EMAIL" --agree-tos
fi

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Ошибка при получении сертификатов"
    echo ""
    echo "Возможные причины:"
    echo "  1. TXT записи не добавлены в DNS"
    echo "  2. Не прошло достаточно времени для распространения DNS"
    echo "  3. Неправильные значения TXT записей"
    echo ""
    echo "Попробуйте снова:"
    echo "  sudo ./install-ssl-dns.sh"
    exit 1
fi

echo ""
echo "✅ Сертификаты получены!"
CERT_PATH="/etc/letsencrypt/live/e-novolunie.ru"

echo ""
echo "3️⃣ Проверка сертификатов..."
echo "----------------------------------------"
if [ -f "$CERT_PATH/fullchain.pem" ] && [ -f "$CERT_PATH/privkey.pem" ]; then
    echo "✅ Сертификаты найдены:"
    ls -lh "$CERT_PATH/"
else
    echo "❌ Сертификаты не найдены в $CERT_PATH"
    exit 1
fi
echo ""

echo "4️⃣ Настройка Nginx с HTTPS..."
echo "----------------------------------------"

# Создаём директорию для webroot (для обновления сертификатов)
mkdir -p /var/www/certbot

# Создаём конфигурацию Nginx
cat > /etc/nginx/sites-available/e-novolunie.ru << 'EOF'
# HTTP сервер - редирект на HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name e-novolunie.ru www.e-novolunie.ru;

    # Разрешаем доступ к ACME challenge для обновления сертификатов
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files $uri =404;
    }

    # Редирект на HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
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
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Корневая директория сайта
    root /var/www/html;
    index index.html;

    # Логи
    access_log /var/log/nginx/e-novolunie.ru.access.log;
    error_log /var/log/nginx/e-novolunie.ru.error.log;

    # Основная конфигурация
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Кэширование статических файлов
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Gzip сжатие
    gzip on;
    gzip_vary on;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Безопасность
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Обработка ошибок
    error_page 404 /index.html;
    error_page 500 502 503 504 /index.html;

    server_tokens off;
    client_max_body_size 10M;
}
EOF

# Активируем конфигурацию
ln -sf /etc/nginx/sites-available/e-novolunie.ru /etc/nginx/sites-enabled/

# Удаляем дефолтную конфигурацию (если есть)
rm -f /etc/nginx/sites-enabled/default

# Проверяем конфигурацию
echo ""
echo "Проверка конфигурации Nginx..."
if nginx -t; then
    echo "✅ Конфигурация Nginx корректна"
else
    echo "❌ Ошибка в конфигурации Nginx"
    exit 1
fi

# Копируем файлы сайта
echo ""
echo "5️⃣ Копирование файлов сайта..."
echo "----------------------------------------"
if [ -d "/root/novolunie" ]; then
    SITE_DIR="/root/novolunie"
elif [ -d "$HOME/novolunie" ]; then
    SITE_DIR="$HOME/novolunie"
else
    echo "⚠️  Директория novolunie не найдена"
    echo "   Скопируйте файлы сайта вручную в /var/www/html/"
    read -p "Продолжить без копирования? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

if [ -n "$SITE_DIR" ]; then
    mkdir -p /var/www/html
    cp -r "$SITE_DIR"/* /var/www/html/ 2>/dev/null || true
    # Исключаем служебные файлы
    rm -f /var/www/html/*.sh /var/www/html/*.md /var/www/html/.git* 2>/dev/null || true
    chown -R www-data:www-data /var/www/html
    echo "✅ Файлы сайта скопированы"
fi

# Открываем порты
echo ""
echo "6️⃣ Настройка файрвола..."
echo "----------------------------------------"
if command -v ufw &> /dev/null; then
    ufw allow 80/tcp
    ufw allow 443/tcp
    echo "✅ Порты 80 и 443 открыты"
else
    echo "⚠️  UFW не установлен, проверьте файрвол вручную"
fi

# Перезагружаем Nginx
echo ""
echo "7️⃣ Перезагрузка Nginx..."
echo "----------------------------------------"
systemctl reload nginx

if [ $? -eq 0 ]; then
    echo "✅ Nginx перезагружен"
else
    echo "❌ Ошибка при перезагрузке Nginx"
    systemctl status nginx
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ SSL сертификат установлен и настроен!"
echo "=========================================="
echo ""
echo "Проверьте работу HTTPS:"
echo "  curl -I https://e-novolunie.ru"
echo ""
echo "Проверьте сертификат:"
echo "  openssl s_client -connect e-novolunie.ru:443 -servername e-novolunie.ru < /dev/null"
echo ""
echo "Настройте автообновление сертификатов:"
echo "  sudo certbot renew --dry-run"
echo ""
