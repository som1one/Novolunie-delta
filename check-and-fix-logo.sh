#!/bin/bash

# Скрипт для проверки и исправления логотипа на сервере

echo "🖼️  Проверка и исправление логотипа"
echo "===================================="
echo ""

cd ~/novolunie || exit 1

echo "1️⃣ Проверка логотипа в репозитории..."
if [ -f "assets/logo.png" ]; then
    echo "✅ Логотип найден в репозитории: assets/logo.png"
    ls -lh assets/logo.png
    FILE_SIZE=$(stat -f%z assets/logo.png 2>/dev/null || stat -c%s assets/logo.png 2>/dev/null || echo "unknown")
    echo "   Размер: $FILE_SIZE байт"
else
    echo "❌ Логотип НЕ найден в репозитории!"
    echo ""
    echo "Подтягивание из Git..."
    git fetch origin main
    git checkout origin/main -- assets/logo.png
    
    if [ -f "assets/logo.png" ]; then
        echo "✅ Логотип подтянут из Git"
        ls -lh assets/logo.png
    else
        echo "❌ Не удалось подтянуть логотип из Git"
        echo ""
        echo "Проверьте:"
        echo "  1. Файл закоммичен в Git: git ls-files assets/logo.png"
        echo "  2. Правильный ли путь: ls -la assets/"
        exit 1
    fi
fi

echo ""
echo "2️⃣ Проверка логотипа на сервере..."

# Проверяем, используется ли Docker или чистый Nginx
if [ -f "docker-compose.yml" ] && docker ps | grep -q novolunie; then
    echo "📦 Обнаружен Docker"
    
    # Проверяем внутри контейнера
    CONTAINER_NAME=$(docker ps | grep novolunie | awk '{print $1}' | head -1)
    if [ -n "$CONTAINER_NAME" ]; then
        echo "Проверка внутри контейнера $CONTAINER_NAME..."
        docker exec "$CONTAINER_NAME" ls -lh /usr/share/nginx/html/assets/logo.png 2>/dev/null
        
        if [ $? -ne 0 ]; then
            echo "⚠️  Логотип не найден в контейнере, пересобираем..."
            docker compose down
            docker compose up -d --build
            
            if [ $? -eq 0 ]; then
                echo "✅ Docker контейнер пересобран"
            else
                echo "❌ Ошибка при пересборке Docker"
            fi
        else
            echo "✅ Логотип найден в контейнере"
        fi
    fi
else
    # Чистый Nginx
    echo "📁 Проверка в Nginx (/var/www/html/)..."
    
    if [ -f "/var/www/html/assets/logo.png" ]; then
        echo "✅ Логотип найден на сервере: /var/www/html/assets/logo.png"
        ls -lh /var/www/html/assets/logo.png
        
        # Сравниваем размеры
        REPO_SIZE=$(stat -f%z assets/logo.png 2>/dev/null || stat -c%s assets/logo.png 2>/dev/null || echo "0")
        SERVER_SIZE=$(stat -f%z /var/www/html/assets/logo.png 2>/dev/null || stat -c%s /var/www/html/assets/logo.png 2>/dev/null || echo "0")
        
        if [ "$REPO_SIZE" != "$SERVER_SIZE" ] && [ "$REPO_SIZE" != "0" ] && [ "$SERVER_SIZE" != "0" ]; then
            echo "⚠️  Размеры не совпадают, обновляем..."
            sudo cp assets/logo.png /var/www/html/assets/logo.png
            sudo chmod 644 /var/www/html/assets/logo.png
            sudo chown www-data:www-data /var/www/html/assets/logo.png 2>/dev/null || true
            echo "✅ Логотип обновлен"
        fi
    else
        echo "❌ Логотип НЕ найден на сервере, копируем..."
        sudo mkdir -p /var/www/html/assets
        sudo cp assets/logo.png /var/www/html/assets/logo.png
        sudo chmod 644 /var/www/html/assets/logo.png
        sudo chown www-data:www-data /var/www/html/assets/logo.png 2>/dev/null || true
        
        if [ -f "/var/www/html/assets/logo.png" ]; then
            echo "✅ Логотип скопирован на сервер"
            ls -lh /var/www/html/assets/logo.png
        else
            echo "❌ Ошибка при копировании"
        fi
    fi
    
    # Перезагрузка Nginx
    if systemctl is-active --quiet nginx; then
        echo "🔄 Перезагрузка Nginx..."
        sudo systemctl reload nginx
        echo "✅ Nginx перезагружен"
    fi
fi

echo ""
echo "3️⃣ Проверка доступности на сайте..."
DOMAIN="e-novolunie.ru"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://${DOMAIN}/assets/logo.png" 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Логотип доступен на сайте: https://${DOMAIN}/assets/logo.png"
elif [ "$HTTP_CODE" = "404" ]; then
    echo "❌ Логотип НЕ найден на сайте (404)"
    echo ""
    echo "Проверьте:"
    echo "  1. Файл на сервере: ls -la /var/www/html/assets/logo.png"
    echo "  2. Права доступа: sudo chmod 644 /var/www/html/assets/logo.png"
    echo "  3. Nginx конфигурацию: sudo nginx -t"
else
    echo "⚠️  Не удалось проверить доступность (код: $HTTP_CODE)"
    echo "Проверьте вручную: curl -I https://${DOMAIN}/assets/logo.png"
fi

echo ""
echo "✅ Проверка завершена!"
echo ""
echo "📋 Резюме:"
echo "  - В репозитории: $([ -f "assets/logo.png" ] && echo "✅" || echo "❌")"
if [ -f "/var/www/html/assets/logo.png" ]; then
    echo "  - На сервере: ✅"
elif [ -f "docker-compose.yml" ] && docker ps | grep -q novolunie; then
    echo "  - В Docker: ✅"
else
    echo "  - На сервере: ❌"
fi
echo "  - На сайте: $([ "$HTTP_CODE" = "200" ] && echo "✅" || echo "❌")"
