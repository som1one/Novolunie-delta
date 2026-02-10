#!/bin/bash

echo "🔍 Полная диагностика недоступности портов 80 и 443"
echo "===================================================="
echo ""

PROJECT_DIR="$HOME/novolunie"
cd "$PROJECT_DIR" || {
    echo "❌ Директория $PROJECT_DIR не найдена"
    exit 1
}

echo "1️⃣ Проверка статуса Docker контейнера..."
echo "----------------------------------------"
if docker ps | grep -q novolunie-web; then
    echo "✅ Контейнер запущен"
    docker compose ps
    echo ""
    
    echo "Проверка проброшенных портов:"
    docker port novolunie-web 2>/dev/null || echo "⚠️  Не удалось получить информацию о портах"
    echo ""
else
    echo "❌ Контейнер НЕ запущен!"
    echo ""
    echo "Запускаем контейнер..."
    docker compose up -d
    sleep 5
    docker compose ps
    echo ""
fi

echo "2️⃣ Проверка процессов на портах 80 и 443..."
echo "----------------------------------------"
echo "Порт 80:"
PROCESS_80=$(sudo lsof -i :80 2>/dev/null | grep -v COMMAND || echo "")
if [ -n "$PROCESS_80" ]; then
    echo "$PROCESS_80"
else
    echo "❌ Ничего не слушает порт 80"
fi
echo ""

echo "Порт 443:"
PROCESS_443=$(sudo lsof -i :443 2>/dev/null | grep -v COMMAND || echo "")
if [ -n "$PROCESS_443" ]; then
    echo "$PROCESS_443"
else
    echo "❌ Ничего не слушает порт 443"
fi
echo ""

echo "3️⃣ Проверка через netstat..."
echo "----------------------------------------"
echo "Порт 80:"
if sudo netstat -tlnp 2>/dev/null | grep -q ":80 "; then
    echo "✅ Порт 80 слушается:"
    sudo netstat -tlnp | grep ":80 "
else
    echo "❌ Порт 80 НЕ слушается"
fi
echo ""

echo "Порт 443:"
if sudo netstat -tlnp 2>/dev/null | grep -q ":443 "; then
    echo "✅ Порт 443 слушается:"
    sudo netstat -tlnp | grep ":443 "
else
    echo "❌ Порт 443 НЕ слушается"
fi
echo ""

echo "4️⃣ Проверка файрвола UFW..."
echo "----------------------------------------"
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status | head -1)
    echo "Статус: $UFW_STATUS"
    echo ""
    
    if echo "$UFW_STATUS" | grep -q "active"; then
        echo "✅ UFW активен"
        echo ""
        echo "Правила для портов 80 и 443:"
        sudo ufw status | grep -E "(80|443)" || {
            echo "❌ Правила для портов 80/443 НЕ найдены!"
            echo ""
            echo "Открываем порты..."
            sudo ufw allow 80/tcp
            sudo ufw allow 443/tcp
            echo "✅ Порты открыты в UFW"
        }
    else
        echo "⚠️  UFW не активен"
    fi
else
    echo "⚠️  UFW не установлен"
fi
echo ""

echo "5️⃣ Проверка iptables..."
echo "----------------------------------------"
if command -v iptables &> /dev/null; then
    echo "Правила INPUT для портов 80 и 443:"
    sudo iptables -L INPUT -n | grep -E "(80|443|ACCEPT)" | head -10 || echo "⚠️  Правила не найдены"
    echo ""
    
    echo "Добавляем правила в iptables (если нужно)..."
    sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null
    sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null
    echo "✅ Правила добавлены"
    echo ""
fi

echo "6️⃣ Проверка системного Nginx..."
echo "----------------------------------------"
if systemctl is-active --quiet nginx 2>/dev/null; then
    echo "⚠️  Системный Nginx запущен и может занимать порты!"
    echo ""
    echo "Останавливаем системный Nginx..."
    sudo systemctl stop nginx
    sudo systemctl disable nginx
    echo "✅ Системный Nginx остановлен"
else
    echo "✅ Системный Nginx не запущен"
fi
echo ""

echo "7️⃣ Проверка конфигурации Docker..."
echo "----------------------------------------"
if [ -f "docker-compose.yml" ]; then
    echo "Проверка проброски портов в docker-compose.yml:"
    if grep -q "80:80" docker-compose.yml && grep -q "443:443" docker-compose.yml; then
        echo "✅ Порты 80 и 443 проброшены в docker-compose.yml"
    else
        echo "❌ Порты НЕ проброшены в docker-compose.yml!"
        echo ""
        echo "Текущая конфигурация:"
        grep -A 5 "ports:" docker-compose.yml || echo "Секция ports не найдена"
    fi
else
    echo "❌ docker-compose.yml не найден!"
fi
echo ""

echo "8️⃣ Перезапуск контейнера..."
echo "----------------------------------------"
docker compose down
sleep 2
docker compose up -d
sleep 5
echo ""

echo "9️⃣ Проверка Nginx внутри контейнера..."
echo "----------------------------------------"
if docker ps | grep -q novolunie-web; then
    echo "Проверка конфигурации Nginx:"
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
    
    echo "Проверка портов внутри контейнера:"
    docker compose exec web netstat -tlnp 2>/dev/null | grep -E ":(80|443)" || {
        docker compose exec web ss -tlnp 2>/dev/null | grep -E ":(80|443)" || {
            echo "⚠️  Не удалось проверить порты внутри контейнера"
        }
    }
else
    echo "❌ Контейнер не запущен после перезапуска!"
    echo ""
    echo "Логи контейнера:"
    docker compose logs --tail=30 web
fi
echo ""

echo "🔟 Тест доступности локально..."
echo "----------------------------------------"
echo "HTTP (порт 80):"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost 2>&1)
if [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "✅ HTTP работает локально (код: $HTTP_CODE)"
else
    echo "❌ HTTP НЕ работает локально (код: $HTTP_CODE)"
    echo "Ответ:"
    curl -v http://localhost 2>&1 | head -20
fi
echo ""

echo "HTTPS (порт 443):"
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 -k https://localhost 2>&1)
if [ "$HTTPS_CODE" = "200" ]; then
    echo "✅ HTTPS работает локально (код: $HTTPS_CODE)"
else
    echo "❌ HTTPS НЕ работает локально (код: $HTTPS_CODE)"
    echo "Ответ:"
    curl -v -k https://localhost 2>&1 | head -20
fi
echo ""

echo "1️⃣1️⃣ Проверка доступности снаружи..."
echo "----------------------------------------"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "не определен")
echo "IP сервера: $SERVER_IP"
echo ""

if [ "$SERVER_IP" != "не определен" ]; then
    echo "Проверка HTTP снаружи:"
    HTTP_EXT_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://$SERVER_IP 2>&1)
    if [ "$HTTP_EXT_CODE" = "301" ] || [ "$HTTP_EXT_CODE" = "200" ]; then
        echo "✅ HTTP доступен снаружи (код: $HTTP_EXT_CODE)"
    else
        echo "❌ HTTP НЕ доступен снаружи (код: $HTTP_EXT_CODE)"
        echo "⚠️  Возможно, файрвол провайдера блокирует порт 80"
    fi
    echo ""
    
    echo "Проверка HTTPS снаружи:"
    HTTPS_EXT_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 -k https://$SERVER_IP 2>&1)
    if [ "$HTTPS_EXT_CODE" = "200" ]; then
        echo "✅ HTTPS доступен снаружи (код: $HTTPS_EXT_CODE)"
    else
        echo "❌ HTTPS НЕ доступен снаружи (код: $HTTPS_EXT_CODE)"
        echo "⚠️  Возможно, файрвол провайдера блокирует порт 443"
    fi
else
    echo "⚠️  Не удалось определить IP сервера"
fi
echo ""

echo "===================================================="
echo "📋 РЕЗЮМЕ ДИАГНОСТИКИ"
echo "===================================================="
echo ""

# Контейнер
if docker ps | grep -q novolunie-web; then
    echo "✅ Контейнер: Запущен"
else
    echo "❌ Контейнер: НЕ запущен"
fi

# Порт 80
if sudo netstat -tlnp 2>/dev/null | grep -q ":80 "; then
    echo "✅ Порт 80: Слушается"
else
    echo "❌ Порт 80: НЕ слушается"
fi

# Порт 443
if sudo netstat -tlnp 2>/dev/null | grep -q ":443 "; then
    echo "✅ Порт 443: Слушается"
else
    echo "❌ Порт 443: НЕ слушается"
fi

# UFW
if command -v ufw &> /dev/null && sudo ufw status | grep -q "active"; then
    if sudo ufw status | grep -qE "(80|443)"; then
        echo "✅ UFW: Порты открыты"
    else
        echo "❌ UFW: Порты НЕ открыты"
    fi
else
    echo "⚠️  UFW: Не активен или не установлен"
fi

# HTTP локально
if [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "✅ HTTP локально: Работает"
else
    echo "❌ HTTP локально: НЕ работает"
fi

# HTTPS локально
if [ "$HTTPS_CODE" = "200" ]; then
    echo "✅ HTTPS локально: Работает"
else
    echo "❌ HTTPS локально: НЕ работает"
fi

echo ""
echo "===================================================="
echo "🔧 РЕКОМЕНДАЦИИ"
echo "===================================================="
echo ""

if ! docker ps | grep -q novolunie-web; then
    echo "1. ❗ Запустите контейнер: docker compose up -d"
    echo ""
fi

if ! sudo netstat -tlnp 2>/dev/null | grep -q ":80 "; then
    echo "2. ❗ Порт 80 не слушается. Проверьте логи: docker compose logs web"
    echo ""
fi

if command -v ufw &> /dev/null && sudo ufw status | grep -q "active"; then
    if ! sudo ufw status | grep -qE "(80|443)"; then
        echo "3. ❗ Откройте порты в UFW: sudo ufw allow 80/tcp && sudo ufw allow 443/tcp"
        echo ""
    fi
fi

if [ "$HTTP_CODE" != "301" ] && [ "$HTTP_CODE" != "200" ]; then
    echo "4. ❗ HTTP не работает локально. Проверьте конфигурацию Nginx"
    echo ""
fi

if [ "$SERVER_IP" != "не определен" ]; then
    if [ "$HTTP_EXT_CODE" != "301" ] && [ "$HTTP_EXT_CODE" != "200" ]; then
        echo "5. ⚠️  HTTP недоступен снаружи. Проверьте файрвол провайдера в панели управления!"
        echo "   - Timeweb: Панель управления → Сервер → Файрвол"
        echo "   - Selectel: Панель управления → Сеть → Файрвол"
        echo "   - DigitalOcean: Networking → Firewalls"
        echo ""
    fi
fi

echo "📝 Для просмотра логов:"
echo "   docker compose logs -f web"
echo ""
echo "📝 Для проверки конфигурации Nginx:"
echo "   docker compose exec web nginx -t"
