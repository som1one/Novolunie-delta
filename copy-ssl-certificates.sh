#!/bin/bash

echo "🔒 Копирование SSL сертификатов в проект"
echo "========================================"
echo ""

DOMAIN="e-novolunie.ru"
PROJECT_DIR="$HOME/novolunie"
LETSENCRYPT_DIR="/etc/letsencrypt/live/$DOMAIN"

cd "$PROJECT_DIR" || {
    echo "❌ Директория $PROJECT_DIR не найдена"
    exit 1
}

echo "1️⃣ Проверка сертификатов в Let's Encrypt..."
echo "----------------------------------------"
if [ -d "$LETSENCRYPT_DIR" ]; then
    echo "✅ Директория найдена: $LETSENCRYPT_DIR"
    ls -la "$LETSENCRYPT_DIR" | grep -E "\.pem$"
else
    echo "❌ Директория не найдена: $LETSENCRYPT_DIR"
    echo ""
    echo "Проверьте путь к сертификатам:"
    sudo ls -la /etc/letsencrypt/live/
    exit 1
fi
echo ""

echo "2️⃣ Создание директории для SSL в проекте..."
echo "----------------------------------------"
mkdir -p ssl
echo "✅ Директория создана: $PROJECT_DIR/ssl"
echo ""

echo "3️⃣ Копирование сертификатов..."
echo "----------------------------------------"

# Копируем сертификаты
if [ -f "$LETSENCRYPT_DIR/fullchain.pem" ]; then
    sudo cp "$LETSENCRYPT_DIR/fullchain.pem" ssl/
    echo "✅ fullchain.pem скопирован"
else
    echo "❌ fullchain.pem не найден"
    exit 1
fi

if [ -f "$LETSENCRYPT_DIR/privkey.pem" ]; then
    sudo cp "$LETSENCRYPT_DIR/privkey.pem" ssl/
    echo "✅ privkey.pem скопирован"
else
    echo "❌ privkey.pem не найден"
    exit 1
fi

if [ -f "$LETSENCRYPT_DIR/chain.pem" ]; then
    sudo cp "$LETSENCRYPT_DIR/chain.pem" ssl/
    echo "✅ chain.pem скопирован"
else
    echo "⚠️  chain.pem не найден (не критично)"
fi
echo ""

echo "4️⃣ Установка прав доступа..."
echo "----------------------------------------"
sudo chown -R $USER:$USER ssl/
chmod 600 ssl/privkey.pem
chmod 644 ssl/*.pem
echo "✅ Права установлены"
echo ""

echo "5️⃣ Проверка скопированных файлов..."
echo "----------------------------------------"
ls -la ssl/
echo ""

echo "6️⃣ Обновление конфигурации из Git..."
echo "----------------------------------------"
git pull origin main
echo ""

echo "7️⃣ Перезапуск контейнера..."
echo "----------------------------------------"
docker compose down
docker compose up -d --build
echo ""

echo "⏳ Ожидание запуска (10 секунд)..."
sleep 10
echo ""

echo "8️⃣ Проверка статуса контейнера..."
echo "----------------------------------------"
docker compose ps
echo ""

echo "9️⃣ Проверка конфигурации Nginx..."
echo "----------------------------------------"
if docker ps | grep -q novolunie-web; then
    docker compose exec web nginx -t 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Конфигурация Nginx корректна"
    else
        echo "❌ Ошибка в конфигурации Nginx"
        echo ""
        echo "Проверьте логи:"
        echo "  docker compose logs web"
        exit 1
    fi
else
    echo "❌ Контейнер не запущен"
    exit 1
fi
echo ""

echo "🔟 Проверка доступности HTTPS..."
echo "----------------------------------------"
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://localhost 2>&1)
if [ "$HTTPS_CODE" = "200" ]; then
    echo "✅ HTTPS работает локально (код: $HTTPS_CODE)"
else
    echo "⚠️  HTTPS недоступен локально (код: $HTTPS_CODE)"
    echo ""
    echo "Проверьте логи:"
    echo "  docker compose logs web"
fi
echo ""

echo "1️⃣1️⃣ Проверка редиректа HTTP -> HTTPS..."
echo "----------------------------------------"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost 2>&1)
if [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "✅ Редирект работает (код: $HTTP_CODE)"
else
    echo "⚠️  Редирект не работает (код: $HTTP_CODE)"
fi
echo ""

echo "========================================"
echo "✅ Копирование сертификатов завершено!"
echo ""
echo "Проверьте сайт:"
echo "  https://$DOMAIN"
echo "  https://www.$DOMAIN"
echo ""
echo "Для просмотра логов:"
echo "  docker compose logs -f web"
