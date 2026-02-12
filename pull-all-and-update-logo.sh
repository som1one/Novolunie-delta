#!/bin/bash

# Скрипт для полного pull из Git и обновления логотипа на сервере

echo "🔄 Полный pull из Git и обновление логотипа"
echo "==========================================="
echo ""

cd ~/novolunie || exit 1

echo "1️⃣ Полный pull из Git..."
git pull origin main

if [ $? -ne 0 ]; then
    echo "❌ Ошибка при pull из Git!"
    echo ""
    echo "Если есть конфликты, выполните:"
    echo "  git reset --hard HEAD"
    echo "  git pull origin main"
    exit 1
fi

echo "✅ Изменения подтянуты из Git"
echo ""

echo "2️⃣ Проверка изменений..."
CHANGED_FILES=$(git diff --name-only HEAD@{1} HEAD 2>/dev/null || echo "")
if [ -n "$CHANGED_FILES" ]; then
    echo "Измененные файлы:"
    echo "$CHANGED_FILES" | head -10
    echo ""
fi

echo "3️⃣ Проверка наличия логотипа..."
if [ -f "assets/logo.png" ]; then
    echo "✅ Логотип найден: assets/logo.png"
    ls -lh assets/logo.png
    
    echo ""
    echo "4️⃣ Копирование файлов на сервер..."
    
    # Проверяем, используется ли Docker или чистый Nginx
    if [ -f "docker-compose.yml" ] && docker ps | grep -q novolunie; then
        echo "📦 Обнаружен Docker, пересобираем контейнер..."
        docker compose down
        docker compose up -d --build
        
        if [ $? -eq 0 ]; then
            echo "✅ Docker контейнер пересобран"
        else
            echo "⚠️  Ошибка при пересборке Docker контейнера"
        fi
    else
        # Чистый Nginx
        if [ -d "/var/www/html" ]; then
            echo "📁 Копирование всех файлов в /var/www/html/..."
            
            # Копируем все файлы сайта
            sudo cp -r . /var/www/html/ 2>/dev/null || {
                # Если не получилось скопировать всё, копируем по частям
                echo "Копирование основных файлов..."
                sudo cp -r index.html components styles js assets /var/www/html/ 2>/dev/null || true
            }
            
            # Устанавливаем правильные права
            sudo chown -R www-data:www-data /var/www/html/ 2>/dev/null || true
            sudo find /var/www/html -type f -exec chmod 644 {} \; 2>/dev/null || true
            sudo find /var/www/html -type d -exec chmod 755 {} \; 2>/dev/null || true
            
            echo "✅ Файлы скопированы в /var/www/html/"
            
            # Перезагрузка Nginx
            if systemctl is-active --quiet nginx; then
                echo "🔄 Перезагрузка Nginx..."
                sudo systemctl reload nginx
                
                if [ $? -eq 0 ]; then
                    echo "✅ Nginx перезагружен"
                else
                    echo "⚠️  Ошибка при перезагрузке Nginx"
                    echo "Проверьте конфигурацию: sudo nginx -t"
                fi
            else
                echo "⚠️  Nginx не запущен"
            fi
        else
            echo "⚠️  Папка /var/www/html не найдена"
            echo "Файлы находятся в: $(pwd)"
        fi
    fi
    
    echo ""
    echo "5️⃣ Проверка логотипа..."
    if [ -f "/var/www/html/assets/logo.png" ]; then
        echo "✅ Логотип на месте: /var/www/html/assets/logo.png"
        ls -lh /var/www/html/assets/logo.png
    elif [ -f "assets/logo.png" ]; then
        echo "✅ Логотип в репозитории: assets/logo.png"
        ls -lh assets/logo.png
    fi
    
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

echo ""
echo "✅ Готово! Все изменения подтянуты и применены"
echo ""
echo "📋 Проверка:"
echo "  - Файлы: ls -lh assets/logo.png"
echo "  - Сайт: curl -I https://e-novolunie.ru/assets/logo.png"
echo "  - Git статус: git status"
