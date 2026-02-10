#!/bin/bash

echo "🔍 Поиск SSL сертификатов на сервере"
echo "======================================"
echo ""

echo "1️⃣ Проверка стандартных путей Let's Encrypt..."
echo "----------------------------------------"
if [ -d "/etc/letsencrypt/live" ]; then
    echo "Директория /etc/letsencrypt/live/ существует:"
    sudo ls -la /etc/letsencrypt/live/
    echo ""
    
    for domain_dir in /etc/letsencrypt/live/*; do
        if [ -d "$domain_dir" ]; then
            domain=$(basename "$domain_dir")
            echo "Проверяем $domain:"
            if [ -f "$domain_dir/fullchain.pem" ]; then
                echo "  ✅ fullchain.pem найден"
            else
                echo "  ❌ fullchain.pem не найден"
            fi
            if [ -f "$domain_dir/privkey.pem" ]; then
                echo "  ✅ privkey.pem найден"
            else
                echo "  ❌ privkey.pem не найден"
            fi
            if [ -f "$domain_dir/chain.pem" ]; then
                echo "  ✅ chain.pem найден"
            else
                echo "  ⚠️  chain.pem не найден (не критично)"
            fi
            echo ""
        fi
    done
else
    echo "❌ Директория /etc/letsencrypt/live/ не существует"
    echo ""
fi

echo "2️⃣ Проверка /etc/ssl/certs/..."
echo "----------------------------------------"
if [ -d "/etc/ssl/certs" ]; then
    echo "Содержимое /etc/ssl/certs/:"
    sudo ls -la /etc/ssl/certs/ | grep -E "(e-novolunie|ssl|cert)" | head -10
    echo ""
else
    echo "❌ Директория /etc/ssl/certs/ не существует"
    echo ""
fi

echo "3️⃣ Проверка /etc/nginx/ssl/..."
echo "----------------------------------------"
if [ -d "/etc/nginx/ssl" ]; then
    echo "Содержимое /etc/nginx/ssl/:"
    sudo ls -la /etc/nginx/ssl/
    echo ""
else
    echo "❌ Директория /etc/nginx/ssl/ не существует"
    echo ""
fi

echo "4️⃣ Проверка /etc/ssl/private/..."
echo "----------------------------------------"
if [ -d "/etc/ssl/private" ]; then
    echo "Содержимое /etc/ssl/private/ (только имена файлов):"
    sudo ls -la /etc/ssl/private/ | grep -E "(e-novolunie|ssl|key)" | head -10
    echo ""
else
    echo "❌ Директория /etc/ssl/private/ не существует"
    echo ""
fi

echo "5️⃣ Поиск файлов сертификатов по всему серверу..."
echo "----------------------------------------"
echo "Ищем fullchain.pem:"
sudo find /etc -name "fullchain.pem" 2>/dev/null | head -5
echo ""

echo "Ищем privkey.pem:"
sudo find /etc -name "privkey.pem" 2>/dev/null | head -5
echo ""

echo "Ищем файлы с именем домена:"
sudo find /etc -name "*e-novolunie*" 2>/dev/null | head -10
echo ""

echo "6️⃣ Проверка текущей конфигурации Nginx..."
echo "----------------------------------------"
if [ -f "/etc/nginx/sites-available/e-novolunie.ru" ]; then
    echo "Текущая конфигурация:"
    sudo grep -E "(ssl_certificate|ssl_certificate_key)" /etc/nginx/sites-available/e-novolunie.ru | head -5
    echo ""
fi

if [ -f "/etc/nginx/sites-enabled/e-novolunie.ru" ]; then
    echo "Активная конфигурация:"
    sudo grep -E "(ssl_certificate|ssl_certificate_key)" /etc/nginx/sites-enabled/e-novolunie.ru | head -5
    echo ""
fi

echo "7️⃣ Проверка процессов Nginx..."
echo "----------------------------------------"
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx запущен"
    echo ""
    echo "Проверяем, какие сертификаты использует Nginx:"
    sudo nginx -T 2>/dev/null | grep -E "(ssl_certificate|ssl_certificate_key)" | head -5
else
    echo "⚠️  Nginx не запущен"
fi
echo ""

echo "8️⃣ Проверка панели управления Timeweb..."
echo "----------------------------------------"
echo "Если сертификаты были получены через панель Timeweb Cloud:"
echo ""
echo "1. Войдите в панель управления Timeweb Cloud"
echo "2. Перейдите: Домены → Ваш домен → SSL"
echo "3. Проверьте, активирован ли SSL сертификат"
echo "4. Если сертификат активирован, но не найден на сервере:"
echo "   - Возможно, нужно скачать сертификаты из панели"
echo "   - Или получить новые через certbot"
echo ""

echo "======================================"
echo "📋 Рекомендации:"
echo ""
echo "Если сертификаты не найдены:"
echo "1. Получите новые через certbot:"
echo "   sudo apt install certbot python3-certbot-nginx -y"
echo "   sudo certbot --nginx -d e-novolunie.ru -d www.e-novolunie.ru"
echo ""
echo "2. Или используйте временную конфигурацию без SSL:"
echo "   ./fix-nginx-ssl.sh"
echo ""
