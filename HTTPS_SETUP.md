# 🔒 Настройка HTTPS для e-novolunie.ru

## Вариант 1: SSL сертификаты уже установлены

Если у вас уже есть SSL сертификаты в директории `~/novolunie/ssl/`, просто обновите конфигурацию:

```bash
cd ~/novolunie
git pull origin main
docker compose down
docker compose up -d --build
```

Убедитесь, что в директории `~/novolunie/ssl/` есть файлы:
- `fullchain.pem` - полная цепочка сертификатов
- `privkey.pem` - приватный ключ
- `chain.pem` - промежуточные сертификаты (опционально)

## Вариант 2: Установка SSL через Certbot (Let's Encrypt)

### Шаг 1: Временно используйте HTTP конфигурацию

```bash
cd ~/novolunie

# Используйте временную HTTP конфигурацию
cp nginx-http-only.conf nginx.conf

# Пересоберите контейнер
docker compose down
docker compose up -d --build

# Проверьте, что сайт доступен по HTTP
curl -I http://e-novolunie.ru
```

### Шаг 2: Установите Certbot на хосте

```bash
# Установите Certbot
sudo apt update
sudo apt install certbot -y
```

### Шаг 3: Получите SSL сертификат

```bash
# Получите сертификат (Certbot автоматически настроит Nginx на хосте)
sudo certbot certonly --standalone -d e-novolunie.ru -d www.e-novolunie.ru

# Или если используете webroot метод (рекомендуется для Docker):
sudo certbot certonly --webroot -w /var/www/html -d e-novolunie.ru -d www.e-novolunie.ru
```

Сертификаты будут сохранены в:
- `/etc/letsencrypt/live/e-novolunie.ru/fullchain.pem`
- `/etc/letsencrypt/live/e-novolunie.ru/privkey.pem`
- `/etc/letsencrypt/live/e-novolunie.ru/chain.pem`

### Шаг 4: Скопируйте сертификаты в проект

```bash
cd ~/novolunie

# Создайте директорию для SSL
mkdir -p ssl

# Скопируйте сертификаты
sudo cp /etc/letsencrypt/live/e-novolunie.ru/fullchain.pem ssl/
sudo cp /etc/letsencrypt/live/e-novolunie.ru/privkey.pem ssl/
sudo cp /etc/letsencrypt/live/e-novolunie.ru/chain.pem ssl/

# Установите правильные права
sudo chown -R $USER:$USER ssl/
chmod 600 ssl/privkey.pem
chmod 644 ssl/*.pem
```

### Шаг 5: Обновите конфигурацию Nginx для HTTPS

```bash
cd ~/novolunie

# Обновите код из Git (там уже есть HTTPS конфигурация)
git pull origin main

# Убедитесь, что nginx.conf использует HTTPS конфигурацию
# (по умолчанию она уже настроена)

# Пересоберите контейнер
docker compose down
docker compose up -d --build

# Проверьте логи
docker compose logs web
```

### Шаг 6: Проверьте HTTPS

```bash
# Проверьте доступность
curl -I https://e-novolunie.ru

# Должен вернуть: HTTP/2 200
```

### Шаг 7: Настройте автообновление сертификатов

```bash
# Проверьте автообновление
sudo certbot renew --dry-run

# Настройте cron для автоматического обновления
sudo crontab -e

# Добавьте строку (обновление каждый день в 3:00):
0 3 * * * certbot renew --quiet && cd ~/novolunie && docker compose restart web
```

## Вариант 3: Использование системного Nginx как reverse proxy

Если вы хотите использовать системный Nginx на хосте для SSL, а Docker контейнер только для статики:

### 1. Установите Nginx на хосте

```bash
sudo apt install nginx certbot python3-certbot-nginx -y
```

### 2. Создайте конфигурацию `/etc/nginx/sites-available/e-novolunie`

```nginx
# HTTP - редирект на HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name e-novolunie.ru www.e-novolunie.ru;
    return 301 https://$host$request_uri;
}

# HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name e-novolunie.ru www.e-novolunie.ru;

    ssl_certificate /etc/letsencrypt/live/e-novolunie.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/e-novolunie.ru/privkey.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 3. Измените порт Docker контейнера

В `docker-compose.yml`:
```yaml
ports:
  - "8080:80"  # Вместо "80:80"
```

### 4. Активируйте конфигурацию и получите SSL

```bash
sudo ln -s /etc/nginx/sites-available/e-novolunie /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
sudo certbot --nginx -d e-novolunie.ru -d www.e-novolunie.ru
```

## Проверка после настройки

```bash
# 1. Проверьте HTTPS
curl -I https://e-novolunie.ru

# 2. Проверьте редирект с HTTP на HTTPS
curl -I http://e-novolunie.ru
# Должен вернуть: HTTP/1.1 301 Moved Permanently

# 3. Проверьте SSL сертификат
openssl s_client -connect e-novolunie.ru:443 -servername e-novolunie.ru

# 4. Проверьте логи
docker compose logs web
```

## Обновление сертификатов

Сертификаты Let's Encrypt действительны 90 дней. Для автоматического обновления:

```bash
# Создайте скрипт обновления
cat > ~/novolunie/update-ssl.sh << 'EOF'
#!/bin/bash
sudo certbot renew --quiet
sudo cp /etc/letsencrypt/live/e-novolunie.ru/fullchain.pem ~/novolunie/ssl/
sudo cp /etc/letsencrypt/live/e-novolunie.ru/privkey.pem ~/novolunie/ssl/
sudo cp /etc/letsencrypt/live/e-novolunie.ru/chain.pem ~/novolunie/ssl/
sudo chown -R $USER:$USER ~/novolunie/ssl/
cd ~/novolunie
docker compose restart web
EOF

chmod +x ~/novolunie/update-ssl.sh

# Добавьте в crontab
crontab -e
# Добавьте: 0 3 * * * /home/user/novolunie/update-ssl.sh
```

## Устранение проблем

### Ошибка: "SSL certificate not found"

Убедитесь, что файлы сертификатов существуют:
```bash
ls -la ~/novolunie/ssl/
```

### Ошибка: "Permission denied"

Исправьте права:
```bash
chmod 600 ~/novolunie/ssl/privkey.pem
chmod 644 ~/novolunie/ssl/*.pem
```

### Ошибка: "Port 443 already in use"

Проверьте, что порт свободен:
```bash
sudo netstat -tulpn | grep :443
```

### Проверка конфигурации Nginx

```bash
docker compose exec web nginx -t
```
