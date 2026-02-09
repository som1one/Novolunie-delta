#!/bin/bash

echo "🔧 Исправление ошибки 503 (проблема с SSL)"
echo "=========================================="
echo ""

cd ~/novolunie || exit 1

# Проверяем наличие SSL сертификатов
if [ ! -f "ssl/fullchain.pem" ] || [ ! -f "ssl/privkey.pem" ]; then
    echo "⚠️  SSL сертификаты не найдены"
    echo ""
    echo "Вариант 1: Использовать временную HTTP конфигурацию"
    echo "Вариант 2: Установить SSL сертификаты"
    echo ""
    read -p "Использовать HTTP конфигурацию? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "1️⃣ Переключение на HTTP конфигурацию..."
        if [ -f "nginx-http-only.conf" ]; then
            cp nginx-http-only.conf nginx.conf
            echo "✅ HTTP конфигурация применена"
        else
            echo "❌ nginx-http-only.conf не найден"
            echo "Обновляю код из Git..."
            git pull origin main
            if [ -f "nginx-http-only.conf" ]; then
                cp nginx-http-only.conf nginx.conf
                echo "✅ HTTP конфигурация применена"
            else
                echo "❌ Не удалось найти HTTP конфигурацию"
                exit 1
            fi
        fi
        
        echo ""
        echo "2️⃣ Пересборка контейнера..."
        docker compose down
        docker compose up -d --build
        
        echo ""
        echo "⏳ Ожидание запуска (5 секунд)..."
        sleep 5
        
        echo ""
        echo "3️⃣ Проверка статуса..."
        docker compose ps
        
        echo ""
        echo "4️⃣ Проверка доступности..."
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost 2>&1)
        if [ "$HTTP_CODE" = "200" ]; then
            echo "✅ Сайт доступен по HTTP (код: $HTTP_CODE)"
            echo ""
            echo "Для настройки HTTPS выполните:"
            echo "  ./setup-https.sh"
        else
            echo "❌ Сайт недоступен (код: $HTTP_CODE)"
            echo ""
            echo "Проверьте логи:"
            echo "  docker compose logs web"
        fi
    else
        echo "Установка SSL сертификатов..."
        echo ""
        echo "Выполните:"
        echo "  ./setup-https.sh"
        echo ""
        echo "Или вручную:"
        echo "  1. docker compose down"
        echo "  2. sudo certbot certonly --standalone -d e-novolunie.ru -d www.e-novolunie.ru"
        echo "  3. mkdir -p ssl"
        echo "  4. sudo cp /etc/letsencrypt/live/e-novolunie.ru/*.pem ssl/"
        echo "  5. sudo chown -R \$USER:\$USER ssl/"
        echo "  6. git pull origin main"
        echo "  7. docker compose up -d --build"
    fi
else
    echo "✅ SSL сертификаты найдены"
    echo ""
    echo "1️⃣ Проверка конфигурации Nginx..."
    docker compose exec web nginx -t 2>&1
    
    if [ $? -ne 0 ]; then
        echo "❌ Ошибка в конфигурации Nginx"
        echo ""
        echo "Проверяю логи..."
        docker compose logs --tail=30 web
        exit 1
    fi
    
    echo ""
    echo "2️⃣ Перезапуск Nginx внутри контейнера..."
    docker compose exec web nginx -s reload 2>&1 || {
        echo "⚠️  Не удалось перезагрузить, перезапускаю контейнер..."
        docker compose restart web
    }
    
    echo ""
    echo "⏳ Ожидание (5 секунд)..."
    sleep 5
    
    echo ""
    echo "3️⃣ Проверка доступности..."
    HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://localhost 2>&1)
    if [ "$HTTPS_CODE" = "200" ]; then
        echo "✅ HTTPS работает (код: $HTTPS_CODE)"
    else
        echo "⚠️  HTTPS недоступен (код: $HTTPS_CODE)"
        echo ""
        echo "Проверьте логи:"
        echo "  docker compose logs web"
    fi
fi

echo ""
echo "=========================================="
echo "✅ Проверка завершена"
