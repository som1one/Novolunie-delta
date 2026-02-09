#!/bin/bash

echo "🔒 Настройка HTTPS для e-novolunie.ru"
echo "======================================"
echo ""

DOMAIN="e-novolunie.ru"
PROJECT_DIR="$HOME/novolunie"

# Переходим в директорию проекта
cd "$PROJECT_DIR" || {
    echo "❌ Директория $PROJECT_DIR не найдена"
    exit 1
}

echo "1️⃣ Проверка текущего состояния..."
echo "----------------------------------------"

# Проверяем, есть ли уже сертификаты
if [ -f "ssl/fullchain.pem" ] && [ -f "ssl/privkey.pem" ]; then
    echo "✅ SSL сертификаты найдены в ssl/"
    echo ""
    echo "Обновляю конфигурацию для HTTPS..."
    git pull origin main
    docker compose down
    docker compose up -d --build
    echo ""
    echo "✅ HTTPS настроен!"
    echo "Проверьте: https://$DOMAIN"
    exit 0
fi

echo "⚠️  SSL сертификаты не найдены"
echo ""

# Проверяем, установлен ли Certbot
if ! command -v certbot &> /dev/null; then
    echo "2️⃣ Установка Certbot..."
    echo "----------------------------------------"
    sudo apt update
    sudo apt install certbot -y
    echo ""
fi

# Временно используем HTTP конфигурацию
echo "3️⃣ Временная настройка HTTP..."
echo "----------------------------------------"
if [ -f "nginx-http-only.conf" ]; then
    cp nginx-http-only.conf nginx.conf
    docker compose down
    docker compose up -d --build
    echo "✅ HTTP конфигурация применена"
else
    echo "⚠️  nginx-http-only.conf не найден, продолжаю..."
fi
echo ""

# Ждем запуска
echo "⏳ Ожидание запуска контейнера (5 секунд)..."
sleep 5

# Проверяем доступность
echo "4️⃣ Проверка доступности сайта..."
echo "----------------------------------------"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN 2>&1)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Сайт доступен по HTTP"
else
    echo "⚠️  Сайт недоступен (код: $HTTP_CODE)"
    echo "Продолжаю установку SSL..."
fi
echo ""

# Получаем SSL сертификат
echo "5️⃣ Получение SSL сертификата..."
echo "----------------------------------------"
echo "Используется метод standalone (порт 80 должен быть свободен)"
echo ""

# Останавливаем контейнер временно для получения сертификата
docker compose down

# Получаем сертификат
sudo certbot certonly --standalone -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN 2>&1

if [ $? -eq 0 ]; then
    echo "✅ SSL сертификат получен"
else
    echo "❌ Ошибка при получении сертификата"
    echo "Попробуйте вручную:"
    echo "  sudo certbot certonly --standalone -d $DOMAIN -d www.$DOMAIN"
    exit 1
fi

# Создаем директорию для SSL
echo ""
echo "6️⃣ Копирование сертификатов..."
echo "----------------------------------------"
mkdir -p ssl

# Копируем сертификаты
sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ssl/
sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ssl/
sudo cp /etc/letsencrypt/live/$DOMAIN/chain.pem ssl/ 2>/dev/null || echo "chain.pem не найден, пропускаю..."

# Устанавливаем права
sudo chown -R $USER:$USER ssl/
chmod 600 ssl/privkey.pem
chmod 644 ssl/*.pem

echo "✅ Сертификаты скопированы"
echo ""

# Обновляем конфигурацию
echo "7️⃣ Обновление конфигурации для HTTPS..."
echo "----------------------------------------"
git pull origin main

# Убеждаемся, что используется HTTPS конфигурация
if [ -f "nginx.conf" ]; then
    # Проверяем, что в конфигурации есть SSL
    if grep -q "ssl_certificate" nginx.conf; then
        echo "✅ HTTPS конфигурация найдена"
    else
        echo "⚠️  HTTPS конфигурация не найдена, используем базовую"
    fi
fi

# Пересобираем контейнер
echo ""
echo "8️⃣ Пересборка контейнера..."
echo "----------------------------------------"
docker compose down
docker compose up -d --build

# Ждем запуска
echo ""
echo "⏳ Ожидание запуска (10 секунд)..."
sleep 10

# Проверяем статус
echo ""
echo "9️⃣ Проверка статуса..."
echo "----------------------------------------"
docker compose ps
echo ""

# Проверяем логи
echo "🔟 Проверка логов..."
echo "----------------------------------------"
docker compose logs --tail=20 web
echo ""

# Проверяем HTTPS
echo "1️⃣1️⃣ Проверка HTTPS..."
echo "----------------------------------------"
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN 2>&1)
if [ "$HTTPS_CODE" = "200" ]; then
    echo "✅ HTTPS работает! (код: $HTTPS_CODE)"
else
    echo "⚠️  HTTPS недоступен (код: $HTTPS_CODE)"
    echo "Проверьте логи: docker compose logs web"
fi
echo ""

# Проверяем редирект с HTTP на HTTPS
echo "1️⃣2️⃣ Проверка редиректа HTTP -> HTTPS..."
echo "----------------------------------------"
REDIRECT_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN 2>&1)
if [ "$REDIRECT_CODE" = "301" ] || [ "$REDIRECT_CODE" = "302" ]; then
    echo "✅ Редирект работает (код: $REDIRECT_CODE)"
else
    echo "⚠️  Редирект не работает (код: $REDIRECT_CODE)"
fi
echo ""

echo "======================================"
echo "✅ Настройка HTTPS завершена!"
echo ""
echo "Проверьте сайт:"
echo "  https://$DOMAIN"
echo "  https://www.$DOMAIN"
echo ""
echo "Для обновления сертификатов:"
echo "  sudo certbot renew"
echo "  ./update-ssl.sh"
echo ""
echo "Для просмотра логов:"
echo "  docker compose logs -f web"
