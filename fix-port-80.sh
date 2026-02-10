#!/bin/bash

echo "🔍 Диагностика и исправление проблемы с портом 80"
echo "=================================================="
echo ""

PROJECT_DIR="$HOME/novolunie"
cd "$PROJECT_DIR" || {
    echo "❌ Директория $PROJECT_DIR не найдена"
    exit 1
}

echo "1️⃣ Проверка статуса контейнера..."
echo "----------------------------------------"
docker compose ps
echo ""

echo "2️⃣ Проверка проброшенных портов..."
echo "----------------------------------------"
if docker ps | grep -q novolunie-web; then
    docker port novolunie-web
    echo ""
    echo "Проверка портов в контейнере:"
    docker compose exec web netstat -tlnp 2>/dev/null | grep -E ":(80|443)" || {
        echo "⚠️  netstat не доступен, проверяем через ss:"
        docker compose exec web ss -tlnp 2>/dev/null | grep -E ":(80|443)" || {
            echo "⚠️  ss не доступен, проверяем через ps:"
            docker compose exec web ps aux | grep nginx
        }
    }
else
    echo "❌ Контейнер не запущен!"
    echo ""
    echo "Запускаем контейнер..."
    docker compose up -d
    sleep 5
    docker compose ps
fi
echo ""

echo "3️⃣ Проверка портов на хосте..."
echo "----------------------------------------"
echo "Проверка порта 80:"
if sudo netstat -tlnp | grep -q ":80 "; then
    echo "✅ Порт 80 слушается:"
    sudo netstat -tlnp | grep ":80 "
else
    echo "❌ Порт 80 не слушается!"
fi
echo ""

echo "Проверка порта 443:"
if sudo netstat -tlnp | grep -q ":443 "; then
    echo "✅ Порт 443 слушается:"
    sudo netstat -tlnp | grep ":443 "
else
    echo "❌ Порт 443 не слушается!"
fi
echo ""

echo "4️⃣ Проверка файрвола (ufw)..."
echo "----------------------------------------"
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status | head -1)
    echo "Статус UFW: $UFW_STATUS"
    echo ""
    
    if echo "$UFW_STATUS" | grep -q "active"; then
        echo "Проверка правил для портов 80 и 443:"
        sudo ufw status | grep -E "(80|443)" || echo "⚠️  Правила для портов 80/443 не найдены"
        echo ""
        
        echo "Открываем порты 80 и 443 в файрволе..."
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        echo "✅ Порты открыты"
    else
        echo "⚠️  UFW не активен"
    fi
else
    echo "⚠️  UFW не установлен"
fi
echo ""

echo "5️⃣ Проверка системного Nginx..."
echo "----------------------------------------"
if systemctl is-active --quiet nginx 2>/dev/null; then
    echo "⚠️  Системный Nginx запущен и может занимать порт 80!"
    echo ""
    echo "Проверяем, на каком порту он слушает:"
    sudo netstat -tlnp | grep nginx | grep ":80 "
    echo ""
    echo "Останавливаем системный Nginx (он не нужен, если используется Docker):"
    sudo systemctl stop nginx
    sudo systemctl disable nginx
    echo "✅ Системный Nginx остановлен"
else
    echo "✅ Системный Nginx не запущен"
fi
echo ""

echo "6️⃣ Проверка других процессов на порту 80..."
echo "----------------------------------------"
PROCESS_ON_80=$(sudo lsof -i :80 2>/dev/null | grep -v COMMAND || echo "")
if [ -n "$PROCESS_ON_80" ]; then
    echo "⚠️  Процессы на порту 80:"
    echo "$PROCESS_ON_80"
    echo ""
    echo "Если это не Docker, нужно остановить процесс:"
    echo "  sudo kill -9 <PID>"
else
    echo "✅ Порт 80 свободен (кроме Docker)"
fi
echo ""

echo "7️⃣ Проверка доступности порта 80 локально..."
echo "----------------------------------------"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost 2>&1)
if [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "✅ HTTP работает локально (код: $HTTP_CODE)"
else
    echo "❌ HTTP не работает локально (код: $HTTP_CODE)"
    echo ""
    echo "Проверяем логи контейнера:"
    docker compose logs --tail=20 web
fi
echo ""

echo "8️⃣ Проверка доступности порта 80 снаружи..."
echo "----------------------------------------"
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "не определен")
echo "IP сервера: $SERVER_IP"
echo ""
echo "Проверка с сервера:"
HTTP_CODE_EXT=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://$SERVER_IP 2>&1)
if [ "$HTTP_CODE_EXT" = "301" ] || [ "$HTTP_CODE_EXT" = "200" ]; then
    echo "✅ HTTP работает снаружи (код: $HTTP_CODE_EXT)"
else
    echo "❌ HTTP не работает снаружи (код: $HTTP_CODE_EXT)"
fi
echo ""

echo "9️⃣ Перезапуск контейнера..."
echo "----------------------------------------"
docker compose restart
sleep 5
echo ""

echo "🔟 Финальная проверка..."
echo "----------------------------------------"
echo "Статус контейнера:"
docker compose ps
echo ""

echo "Проверка портов:"
docker port novolunie-web 2>/dev/null || echo "⚠️  Не удалось получить информацию о портах"
echo ""

echo "Проверка Nginx внутри контейнера:"
if docker compose exec web nginx -t 2>&1 | grep -q "successful"; then
    echo "✅ Конфигурация Nginx корректна"
else
    echo "❌ Ошибка в конфигурации Nginx:"
    docker compose exec web nginx -t 2>&1
fi
echo ""

echo "Проверка процессов Nginx:"
docker compose exec web ps aux | grep nginx | grep -v grep || echo "❌ Nginx не запущен в контейнере"
echo ""

echo "=================================================="
echo "✅ Диагностика завершена!"
echo ""
echo "📋 Резюме:"
echo "  - Контейнер: $(docker ps | grep -q novolunie-web && echo '✅ Запущен' || echo '❌ Не запущен')"
echo "  - Порт 80: $(sudo netstat -tlnp | grep -q ':80 ' && echo '✅ Открыт' || echo '❌ Закрыт')"
echo "  - Порт 443: $(sudo netstat -tlnp | grep -q ':443 ' && echo '✅ Открыт' || echo '❌ Закрыт')"
echo "  - HTTP локально: $(curl -s -o /dev/null -w '%{http_code}' --max-time 2 http://localhost 2>&1)"
echo ""
echo "🔧 Если проблема не решена, проверьте:"
echo "  1. Логи контейнера: docker compose logs web"
echo "  2. Файрвол провайдера (может блокировать порты)"
echo "  3. Настройки балансировщика нагрузки"
echo ""
echo "📝 Для просмотра логов в реальном времени:"
echo "  docker compose logs -f web"
