#!/bin/bash

# Скрипт для подтягивания только логотипа из Git

echo "🖼️  Подтягивание логотипа из Git"
echo "================================"
echo ""

cd ~/novolunie || exit 1

echo "1️⃣ Подтягивание изменений из Git..."
git pull origin main

echo ""
echo "2️⃣ Проверка наличия логотипа..."
if [ -f "assets/logo.png" ]; then
    echo "✅ Логотип найден: assets/logo.png"
    ls -lh assets/logo.png
    
    echo ""
    echo "3️⃣ Копирование логотипа на сервер..."
    
    # Проверяем, используется ли Docker или чистый Nginx
    if [ -f "docker-compose.yml" ] && docker ps | grep -q novolunie; then
        echo "📦 Обнаружен Docker, пересобираем контейнер..."
        docker compose down
        docker compose up -d --build
        echo "✅ Docker контейнер пересобран"
    else
        # Чистый Nginx
        if [ -d "/var/www/html" ]; then
            echo "📁 Копирование в /var/www/html/assets/..."
            sudo mkdir -p /var/www/html/assets
            sudo cp assets/logo.png /var/www/html/assets/logo.png
            sudo chmod 644 /var/www/html/assets/logo.png
            sudo chown www-data:www-data /var/www/html/assets/logo.png 2>/dev/null || true
            echo "✅ Логотип скопирован в /var/www/html/assets/"
            
            # Перезагрузка Nginx
            if systemctl is-active --quiet nginx; then
                echo "🔄 Перезагрузка Nginx..."
                sudo systemctl reload nginx
                echo "✅ Nginx перезагружен"
            fi
        else
            echo "⚠️  Папка /var/www/html не найдена"
            echo "Логотип находится в: $(pwd)/assets/logo.png"
        fi
    fi
    
    echo ""
    echo "✅ Готово! Логотип обновлен"
    echo ""
    echo "Проверка:"
    echo "  ls -lh assets/logo.png"
    
else
    echo "❌ Логотип НЕ найден в assets/logo.png"
    echo ""
    echo "Проверьте:"
    echo "  1. Файл закоммичен в Git?"
    echo "  2. Правильный ли путь?"
    echo ""
    echo "Список файлов в assets/:"
    ls -la assets/ 2>/dev/null || echo "Папка assets не найдена"
fi
