# 🔒 Быстрое исправление: SSL сертификаты уже есть на сервере

## Проблема
SSL сертификаты установлены на сервере, но не подключены к Docker контейнеру.

## Решение (одна команда)

```bash
cd ~/novolunie
git pull origin main
chmod +x copy-ssl-certificates.sh
./copy-ssl-certificates.sh
```

## Или вручную:

```bash
cd ~/novolunie

# 1. Создайте директорию для SSL
mkdir -p ssl

# 2. Скопируйте сертификаты из Let's Encrypt
sudo cp /etc/letsencrypt/live/e-novolunie.ru/fullchain.pem ssl/
sudo cp /etc/letsencrypt/live/e-novolunie.ru/privkey.pem ssl/
sudo cp /etc/letsencrypt/live/e-novolunie.ru/chain.pem ssl/

# 3. Установите правильные права
sudo chown -R $USER:$USER ssl/
chmod 600 ssl/privkey.pem
chmod 644 ssl/*.pem

# 4. Обновите конфигурацию
git pull origin main

# 5. Перезапустите контейнер
docker compose down
docker compose up -d --build

# 6. Проверьте
curl -I https://e-novolunie.ru
```

## Проверка после исправления

```bash
# Проверьте HTTPS
curl -I https://e-novolunie.ru

# Проверьте логи
docker compose logs web

# Проверьте конфигурацию Nginx
docker compose exec web nginx -t
```

## Если домен отличается

Если ваш домен не `e-novolunie.ru`, замените в командах:

```bash
# Найдите правильный путь к сертификатам
sudo ls -la /etc/letsencrypt/live/

# Используйте правильное имя домена
sudo cp /etc/letsencrypt/live/ВАШ_ДОМЕН/fullchain.pem ssl/
sudo cp /etc/letsencrypt/live/ВАШ_ДОМЕН/privkey.pem ssl/
sudo cp /etc/letsencrypt/live/ВАШ_ДОМЕН/chain.pem ssl/
```
