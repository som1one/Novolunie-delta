#!/bin/bash

echo "🔍 Проверка DNS TXT записей для certbot"
echo "========================================"
echo ""

echo "1️⃣ Проверка TXT записи для e-novolunie.ru..."
echo "----------------------------------------"
echo "Ищем: _acme-challenge.e-novolunie.ru"
echo ""

TXT_RECORD=$(dig +short TXT _acme-challenge.e-novolunie.ru 2>/dev/null || echo "")

if [ -n "$TXT_RECORD" ]; then
    echo "✅ TXT запись найдена:"
    echo "$TXT_RECORD"
else
    echo "❌ TXT запись не найдена"
    echo ""
    echo "Нужно добавить TXT запись в DNS:"
    echo "  Имя: _acme-challenge.e-novolunie.ru"
    echo "  Значение: (будет показано certbot)"
fi
echo ""

echo "2️⃣ Проверка TXT записи для www.e-novolunie.ru..."
echo "----------------------------------------"
echo "Ищем: _acme-challenge.www.e-novolunie.ru"
echo ""

TXT_RECORD_WWW=$(dig +short TXT _acme-challenge.www.e-novolunie.ru 2>/dev/null || echo "")

if [ -n "$TXT_RECORD_WWW" ]; then
    echo "✅ TXT запись найдена:"
    echo "$TXT_RECORD_WWW"
else
    echo "❌ TXT запись не найдена"
    echo ""
    echo "Нужно добавить TXT запись в DNS:"
    echo "  Имя: _acme-challenge.www.e-novolunie.ru"
    echo "  Значение: (будет показано certbot)"
fi
echo ""

echo "3️⃣ Проверка через Google DNS Toolbox..."
echo "----------------------------------------"
echo "Проверьте также через веб-интерфейс:"
echo "  https://toolbox.googleapps.com/apps/dig/#TXT/_acme-challenge.e-novolunie.ru"
echo "  https://toolbox.googleapps.com/apps/dig/#TXT/_acme-challenge.www.e-novolunie.ru"
echo ""

echo "========================================"
echo "📋 ИНСТРУКЦИЯ ПО ДОБАВЛЕНИЮ TXT ЗАПИСЕЙ"
echo "========================================"
echo ""
echo "1. Войдите в панель управления доменом (Timeweb Cloud)"
echo "2. Перейдите: Домены → e-novolunie.ru → DNS"
echo "3. Добавьте TXT записи:"
echo ""
echo "   Запись 1:"
echo "     Тип: TXT"
echo "     Имя: _acme-challenge.e-novolunie.ru"
echo "     Значение: (значение из certbot для e-novolunie.ru)"
echo ""
echo "   Запись 2:"
echo "     Тип: TXT"
echo "     Имя: _acme-challenge.www.e-novolunie.ru"
echo "     Значение: (значение из certbot для www.e-novolunie.ru)"
echo ""
echo "4. Сохраните изменения"
echo "5. Подождите 2-5 минут для распространения DNS"
echo "6. Проверьте записи:"
echo "   dig TXT _acme-challenge.e-novolunie.ru"
echo "   dig TXT _acme-challenge.www.e-novolunie.ru"
echo ""
echo "7. После проверки запустите certbot снова:"
echo "   sudo certbot certonly --manual --preferred-challenges dns -d e-novolunie.ru -d www.e-novolunie.ru"
echo ""

if [ -z "$TXT_RECORD" ] || [ -z "$TXT_RECORD_WWW" ]; then
    echo "⚠️  TXT записи не найдены. Добавьте их в DNS перед продолжением."
else
    echo "✅ TXT записи найдены! Можно продолжать с certbot."
fi
