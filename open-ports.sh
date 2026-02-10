#!/bin/bash

echo "🔓 Открытие портов 80 и 443"
echo "============================"
echo ""

echo "1️⃣ Проверка статуса UFW (файрвол Ubuntu)..."
echo "----------------------------------------"
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status | head -1)
    echo "Статус: $UFW_STATUS"
    echo ""
    
    if echo "$UFW_STATUS" | grep -q "active"; then
        echo "✅ UFW активен"
        echo ""
        echo "Текущие правила для портов 80 и 443:"
        sudo ufw status | grep -E "(80|443)" || echo "⚠️  Правила для портов 80/443 не найдены"
        echo ""
        
        echo "2️⃣ Открытие портов 80 и 443..."
        echo "----------------------------------------"
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        echo "✅ Порты открыты"
        echo ""
        
        echo "3️⃣ Проверка правил..."
        echo "----------------------------------------"
        sudo ufw status numbered | grep -E "(80|443)"
        echo ""
    else
        echo "⚠️  UFW не активен (порты не блокируются UFW)"
        echo ""
        echo "Активируем UFW и открываем порты:"
        sudo ufw --force enable
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        echo "✅ UFW активирован, порты открыты"
        echo ""
    fi
else
    echo "⚠️  UFW не установлен"
    echo ""
fi

echo "4️⃣ Проверка iptables (если используется)..."
echo "----------------------------------------"
if command -v iptables &> /dev/null; then
    echo "Проверка правил iptables для портов 80 и 443:"
    sudo iptables -L INPUT -n | grep -E "(80|443)" || echo "⚠️  Правила не найдены"
    echo ""
    
    echo "Открываем порты в iptables:"
    sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
    sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT
    echo "✅ Правила добавлены"
    echo ""
    
    echo "Сохраняем правила iptables..."
    if command -v iptables-save &> /dev/null; then
        sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null 2>&1 || {
            echo "⚠️  Не удалось сохранить правила автоматически"
            echo "Сохраните вручную: sudo iptables-save > /etc/iptables/rules.v4"
        }
    fi
    echo ""
fi

echo "5️⃣ Проверка firewalld (если используется)..."
echo "----------------------------------------"
if command -v firewall-cmd &> /dev/null; then
    echo "Проверка статуса firewalld:"
    sudo firewall-cmd --state 2>/dev/null || echo "⚠️  firewalld не активен"
    echo ""
    
    if sudo firewall-cmd --state 2>/dev/null | grep -q "running"; then
        echo "Открываем порты в firewalld:"
        sudo firewall-cmd --permanent --add-port=80/tcp
        sudo firewall-cmd --permanent --add-port=443/tcp
        sudo firewall-cmd --reload
        echo "✅ Порты открыты"
        echo ""
    fi
fi

echo "6️⃣ Проверка доступности портов..."
echo "----------------------------------------"
echo "Проверка порта 80:"
if sudo netstat -tlnp 2>/dev/null | grep -q ":80 "; then
    echo "✅ Порт 80 слушается:"
    sudo netstat -tlnp | grep ":80 "
else
    echo "⚠️  Порт 80 не слушается (возможно, контейнер не запущен)"
fi
echo ""

echo "Проверка порта 443:"
if sudo netstat -tlnp 2>/dev/null | grep -q ":443 "; then
    echo "✅ Порт 443 слушается:"
    sudo netstat -tlnp | grep ":443 "
else
    echo "⚠️  Порт 443 не слушается (возможно, контейнер не запущен)"
fi
echo ""

echo "7️⃣ Тест доступности локально..."
echo "----------------------------------------"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost 2>&1)
if [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "✅ HTTP работает (код: $HTTP_CODE)"
else
    echo "⚠️  HTTP не работает (код: $HTTP_CODE)"
fi

HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 -k https://localhost 2>&1)
if [ "$HTTPS_CODE" = "200" ]; then
    echo "✅ HTTPS работает (код: $HTTPS_CODE)"
else
    echo "⚠️  HTTPS не работает (код: $HTTPS_CODE)"
fi
echo ""

echo "============================"
echo "✅ Открытие портов завершено!"
echo ""
echo "📋 Резюме:"
echo "  - UFW: $(sudo ufw status 2>/dev/null | head -1 || echo 'не установлен')"
echo "  - Порт 80: $(sudo netstat -tlnp 2>/dev/null | grep -q ':80 ' && echo '✅ Открыт' || echo '⚠️  Не слушается')"
echo "  - Порт 443: $(sudo netstat -tlnp 2>/dev/null | grep -q ':443 ' && echo '✅ Открыт' || echo '⚠️  Не слушается')"
echo ""
echo "⚠️  ВАЖНО: Если порты всё ещё недоступны снаружи, проверьте:"
echo "  1. Файрвол провайдера (панель управления хостингом)"
echo "  2. Группы безопасности (Security Groups) в облаке"
echo "  3. Запущен ли Docker контейнер: docker compose ps"
echo ""
echo "📝 Для проверки снаружи:"
echo "  curl -I http://$(curl -s ifconfig.me || echo 'ВАШ_IP')"
echo "  curl -I https://e-novolunie.ru"
