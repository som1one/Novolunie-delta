#!/bin/bash

echo "🔧 Исправление ошибки 503 для e-novolunie.ru"
echo ""

# Переходим в директорию проекта
cd ~/novolunie || {
    echo "❌ Директория ~/novolunie не найдена"
    exit 1
}

echo "📥 Обновляем код из Git..."
git pull origin main

echo ""
echo "🛑 Останавливаем контейнер..."
docker compose down

echo ""
echo "🔨 Пересобираем контейнер..."
docker compose up -d --build

echo ""
echo "⏳ Ждем запуска (5 секунд)..."
sleep 5

echo ""
echo "📊 Проверяем статус контейнера:"
docker compose ps

echo ""
echo "🔍 Проверяем конфигурацию Nginx:"
docker compose exec web nginx -t 2>&1 || echo "⚠️  Не удалось проверить конфигурацию"

echo ""
echo "📋 Последние логи:"
docker compose logs --tail=20 web

echo ""
echo "🌐 Проверяем доступность:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
echo "HTTP код: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Сайт доступен локально"
else
    echo "❌ Сайт недоступен локально (код: $HTTP_CODE)"
fi

echo ""
echo "🔍 Проверяем порты:"
sudo netstat -tulpn | grep :80 || echo "⚠️  Порт 80 не найден в netstat"

echo ""
echo "✅ Диагностика завершена!"
echo ""
echo "Проверьте сайт: http://e-novolunie.ru"
echo ""
echo "Для просмотра логов в реальном времени:"
echo "  docker compose logs -f web"
