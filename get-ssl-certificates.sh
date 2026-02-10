#!/bin/bash

echo "🔒 Получение SSL сертификатов через Certbot"
echo "============================================"
echo ""

echo "1️⃣ Проверка установки certbot..."
echo "----------------------------------------"
if command -v certbot &> /dev/null; then
    echo "✅ Certbot уже установлен"
    certbot --version
else
    echo "Устанавливаем certbot..."
    sudo apt update
    sudo apt install certbot python3-certbot-nginx -y
    echo "✅ Certbot установлен"
fi
echo ""

echo "2️⃣ Получение SSL сертификатов..."
echo "----------------------------------------"
echo "Получаем сертификаты для доменов:"
echo "  - e-novolunie.ru"
echo "  - www.e-novolunie.ru"
echo ""

# Используем флаг для автоматического получения без интерактивного ввода email
# Email можно указать через переменную окружения или использовать --register-unsafely-without-email
# Но лучше использовать email через переменную

read -p "Введите email адрес для уведомлений (или нажмите Enter для пропуска): " EMAIL

if [ -z "$EMAIL" ]; then
    echo "Получаем сертификаты без email (не рекомендуется, но работает)..."
    sudo certbot --nginx -d e-novolunie.ru -d www.e-novolunie.ru --register-unsafely-without-email --agree-tos --non-interactive
else
    echo "Используем email: $EMAIL"
    sudo certbot --nginx -d e-novolunie.ru -d www.e-novolunie.ru --email "$EMAIL" --agree-tos --non-interactive
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SSL сертификаты успешно получены!"
    echo ""
    echo "3️⃣ Проверка конфигурации Nginx..."
    echo "----------------------------------------"
    if sudo nginx -t; then
        echo "✅ Конфигурация Nginx корректна"
    else
        echo "❌ Ошибка в конфигурации Nginx"
        exit 1
    fi
    echo ""
    
    echo "4️⃣ Перезапуск Nginx..."
    echo "----------------------------------------"
    sudo systemctl reload nginx
    echo "✅ Nginx перезагружен"
    echo ""
    
    echo "5️⃣ Проверка доступности HTTPS..."
    echo "----------------------------------------"
    HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 -k https://localhost 2>&1)
    if [ "$HTTPS_CODE" = "200" ]; then
        echo "✅ HTTPS работает (код: $HTTPS_CODE)"
    else
        echo "⚠️  HTTPS вернул код: $HTTPS_CODE"
    fi
    echo ""
    
    echo "============================================"
    echo "✅ SSL сертификаты получены и настроены!"
    echo ""
    echo "🌐 Проверьте сайт:"
    echo "  https://e-novolunie.ru"
    echo "  https://www.e-novolunie.ru"
    echo ""
    echo "📝 Certbot автоматически настроил:"
    echo "  ✅ SSL сертификаты"
    echo "  ✅ Редирект HTTP → HTTPS"
    echo "  ✅ Автоматическое обновление сертификатов"
    echo ""
    echo "📅 Сертификаты будут автоматически обновляться"
    echo "   Проверка обновления: sudo certbot renew --dry-run"
else
    echo ""
    echo "❌ Ошибка при получении сертификатов"
    echo ""
    echo "Возможные причины:"
    echo "  1. Домен не указывает на этот сервер"
    echo "  2. Порты 80 и 443 закрыты"
    echo "  3. Nginx не запущен"
    echo ""
    echo "Проверьте:"
    echo "  sudo systemctl status nginx"
    echo "  sudo netstat -tlnp | grep -E ':(80|443) '"
    exit 1
fi
