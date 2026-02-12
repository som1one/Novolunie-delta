#!/bin/bash

# Скрипт для копирования логотипа на сервер

echo "📁 Копирование логотипа на сервер"
echo "=================================="
echo ""

cd ~/novolunie || exit 1

if [ ! -f "assets/logo.png" ]; then
    echo "❌ Логотип не найден в репозитории!"
    exit 1
fi

echo "✅ Логотип найден: assets/logo.png"
ls -lh assets/logo.png

echo ""
echo "1️⃣ Копирование в /var/www/html/assets/..."

# Создаем папку если нет
sudo mkdir -p /var/www/html/assets

# Копируем файл
sudo cp assets/logo.png /var/www/html/assets/logo.png

if [ $? -eq 0 ]; then
    echo "✅ Файл скопирован"
else
    echo "❌ Ошибка при копировании"
    exit 1
fi

# Устанавливаем права
sudo chmod 644 /var/www/html/assets/logo.png
sudo chown www-data:www-data /var/www/html/assets/logo.png 2>/dev/null || true

echo ""
echo "2️⃣ Проверка скопированного файла..."
if [ -f "/var/www/html/assets/logo.png" ]; then
    echo "✅ Логотип на сервере: /var/www/html/assets/logo.png"
    ls -lh /var/www/html/assets/logo.png
    
    # Сравниваем размеры
    REPO_SIZE=$(stat -c%s assets/logo.png 2>/dev/null || stat -f%z assets/logo.png 2>/dev/null || echo "0")
    SERVER_SIZE=$(stat -c%s /var/www/html/assets/logo.png 2>/dev/null || stat -f%z /var/www/html/assets/logo.png 2>/dev/null || echo "0")
    
    if [ "$REPO_SIZE" = "$SERVER_SIZE" ] && [ "$REPO_SIZE" != "0" ]; then
        echo "✅ Размеры совпадают: $REPO_SIZE байт"
    else
        echo "⚠️  Размеры не совпадают (репо: $REPO_SIZE, сервер: $SERVER_SIZE)"
    fi
else
    echo "❌ Файл не найден на сервере!"
    exit 1
fi

echo ""
echo "3️⃣ Перезагрузка Nginx..."
if systemctl is-active --quiet nginx; then
    sudo systemctl reload nginx
    echo "✅ Nginx перезагружен"
else
    echo "⚠️  Nginx не запущен"
fi

echo ""
echo "4️⃣ Проверка доступности на сайте..."
DOMAIN="e-novolunie.ru"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://${DOMAIN}/assets/logo.png" 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Логотип доступен на сайте: https://${DOMAIN}/assets/logo.png"
    echo ""
    echo "Проверьте в браузере: https://${DOMAIN}/assets/logo.png"
elif [ "$HTTP_CODE" = "404" ]; then
    echo "❌ Логотип НЕ найден на сайте (404)"
    echo ""
    echo "Проверьте:"
    echo "  1. Nginx конфигурацию: sudo nginx -t"
    echo "  2. Логи: sudo tail -f /var/log/nginx/error.log"
    echo "  3. Путь в HTML: grep -r 'logo.png' index.html"
else
    echo "⚠️  Не удалось проверить (код: $HTTP_CODE)"
    echo "Проверьте вручную: curl -I https://${DOMAIN}/assets/logo.png"
fi

echo ""
echo "✅ Готово!"
