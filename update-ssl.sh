#!/bin/bash

echo "🔄 Обновление SSL сертификатов"
echo "==============================="
echo ""

DOMAIN="e-novolunie.ru"
PROJECT_DIR="$HOME/novolunie"

cd "$PROJECT_DIR" || {
    echo "❌ Директория $PROJECT_DIR не найдена"
    exit 1
}

# Обновляем сертификаты
echo "1️⃣ Обновление сертификатов через Certbot..."
sudo certbot renew --quiet

if [ $? -eq 0 ]; then
    echo "✅ Сертификаты обновлены"
else
    echo "⚠️  Ошибка при обновлении сертификатов"
    exit 1
fi

# Копируем обновленные сертификаты
echo ""
echo "2️⃣ Копирование обновленных сертификатов..."
mkdir -p ssl

sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ssl/
sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ssl/
sudo cp /etc/letsencrypt/live/$DOMAIN/chain.pem ssl/ 2>/dev/null || true

# Устанавливаем права
sudo chown -R $USER:$USER ssl/
chmod 600 ssl/privkey.pem
chmod 644 ssl/*.pem

echo "✅ Сертификаты скопированы"
echo ""

# Перезапускаем контейнер
echo "3️⃣ Перезапуск контейнера..."
docker compose restart web

echo ""
echo "✅ Обновление завершено!"
echo ""
echo "Проверьте: https://$DOMAIN"
