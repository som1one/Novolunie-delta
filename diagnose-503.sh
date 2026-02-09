#!/bin/bash

echo "🔍 Детальная диагностика ошибки 503"
echo "===================================="
echo ""

# Переходим в директорию проекта
cd ~/novolunie || {
    echo "❌ Директория ~/novolunie не найдена"
    exit 1
}

echo "1️⃣ Проверка статуса Docker контейнера:"
echo "----------------------------------------"
docker compose ps
echo ""

echo "2️⃣ Проверка запущенных контейнеров:"
echo "----------------------------------------"
docker ps -a | grep novolunie || echo "⚠️  Контейнер novolunie не найден"
echo ""

echo "3️⃣ Проверка портов на хосте:"
echo "----------------------------------------"
echo "Порт 80:"
sudo netstat -tulpn | grep :80 || sudo ss -tulpn | grep :80 || echo "⚠️  Порт 80 не слушается"
echo ""
echo "Порт 443:"
sudo netstat -tulpn | grep :443 || sudo ss -tulpn | grep :443 || echo "⚠️  Порт 443 не слушается"
echo ""

echo "4️⃣ Проверка системного Nginx:"
echo "----------------------------------------"
if systemctl is-active --quiet nginx 2>/dev/null; then
    echo "⚠️  ВНИМАНИЕ: Системный Nginx запущен и может занимать порт 80!"
    sudo systemctl status nginx --no-pager | head -5
else
    echo "✅ Системный Nginx не запущен"
fi
echo ""

echo "5️⃣ Проверка логов контейнера:"
echo "----------------------------------------"
if docker ps | grep -q novolunie-web; then
    echo "Последние 30 строк логов:"
    docker compose logs --tail=30 web
else
    echo "❌ Контейнер не запущен"
fi
echo ""

echo "6️⃣ Проверка конфигурации Nginx внутри контейнера:"
echo "----------------------------------------"
if docker ps | grep -q novolunie-web; then
    docker compose exec web nginx -t 2>&1 || echo "⚠️  Не удалось проверить конфигурацию"
else
    echo "⚠️  Контейнер не запущен, проверка невозможна"
fi
echo ""

echo "7️⃣ Проверка доступности внутри контейнера:"
echo "----------------------------------------"
if docker ps | grep -q novolunie-web; then
    echo "Проверка localhost внутри контейнера:"
    docker compose exec web wget -q -O- http://localhost 2>&1 | head -5 || echo "⚠️  Не удалось подключиться"
else
    echo "⚠️  Контейнер не запущен"
fi
echo ""

echo "8️⃣ Проверка файлов сайта в контейнере:"
echo "----------------------------------------"
if docker ps | grep -q novolunie-web; then
    echo "Проверка index.html:"
    docker compose exec web ls -la /usr/share/nginx/html/index.html 2>&1 || echo "⚠️  index.html не найден"
    echo ""
    echo "Проверка nginx.conf:"
    docker compose exec web cat /etc/nginx/conf.d/default.conf | head -10 || echo "⚠️  Конфигурация не найдена"
else
    echo "⚠️  Контейнер не запущен"
fi
echo ""

echo "9️⃣ Проверка сетевых подключений Docker:"
echo "----------------------------------------"
docker network ls | grep novolunie || echo "⚠️  Сеть novolunie не найдена"
echo ""

echo "🔟 Проверка доступности с хоста:"
echo "----------------------------------------"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost 2>&1)
echo "HTTP код localhost: $HTTP_CODE"
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Сайт доступен локально"
elif [ "$HTTP_CODE" = "503" ]; then
    echo "❌ Ошибка 503 - сервис недоступен"
else
    echo "⚠️  Неожиданный код: $HTTP_CODE"
fi
echo ""

echo "1️⃣1️⃣ Проверка DNS:"
echo "----------------------------------------"
echo "e-novolunie.ru:"
nslookup e-novolunie.ru 2>&1 | grep -A 2 "Name:" || dig e-novolunie.ru +short || echo "⚠️  DNS не настроен"
echo ""

echo "===================================="
echo "✅ Диагностика завершена!"
echo ""
echo "Если контейнер не запущен, выполните:"
echo "  cd ~/novolunie && docker compose up -d --build"
echo ""
echo "Если системный Nginx занимает порт 80:"
echo "  sudo systemctl stop nginx"
echo "  sudo systemctl disable nginx"
echo "  docker compose restart"
