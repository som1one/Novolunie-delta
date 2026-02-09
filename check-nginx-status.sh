#!/bin/bash

echo "🔍 Проверка статуса Nginx в контейнере"
echo "======================================"
echo ""

cd ~/novolunie || exit 1

echo "1️⃣ Статус контейнера:"
docker compose ps
echo ""

echo "2️⃣ Логи контейнера (последние 50 строк):"
docker compose logs --tail=50 web
echo ""

echo "3️⃣ Проверка процессов Nginx внутри контейнера:"
if docker ps | grep -q novolunie-web; then
    docker compose exec web ps aux | grep nginx || echo "⚠️  Nginx не запущен"
else
    echo "❌ Контейнер не запущен"
fi
echo ""

echo "4️⃣ Проверка конфигурации Nginx:"
if docker ps | grep -q novolunie-web; then
    docker compose exec web nginx -t 2>&1
else
    echo "⚠️  Контейнер не запущен"
fi
echo ""

echo "5️⃣ Проверка SSL сертификатов:"
if [ -d "ssl" ]; then
    echo "Директория ssl существует:"
    ls -la ssl/ 2>/dev/null || echo "⚠️  Директория пуста"
else
    echo "❌ Директория ssl не найдена"
fi
echo ""

echo "6️⃣ Проверка доступности внутри контейнера:"
if docker ps | grep -q novolunie-web; then
    echo "Проверка localhost:"
    docker compose exec web wget -q -O- http://localhost 2>&1 | head -5 || echo "⚠️  Не удалось подключиться"
else
    echo "⚠️  Контейнер не запущен"
fi
