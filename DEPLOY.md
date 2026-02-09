# Инструкция по деплою сайта на сервер с доменом

## Вариант 1: Nginx (рекомендуется для статики)

### 1. Подготовка сервера

```bash
# Обновляем систему
sudo apt update && sudo apt upgrade -y

# Устанавливаем Nginx
sudo apt install nginx -y

# Запускаем Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 2. Загрузка файлов на сервер

```bash
# Создаем директорию для сайта
sudo mkdir -p /var/www/novolunie

# Загружаем файлы (через scp или rsync)
# С локального компьютера:
scp -r * user@your-server-ip:/var/www/novolunie/

# Или через rsync (лучше для обновлений):
rsync -avz --exclude 'node_modules' --exclude '.git' ./ user@your-server-ip:/var/www/novolunie/
```

### 3. Настройка прав доступа

```bash
# Устанавливаем владельца
sudo chown -R www-data:www-data /var/www/novolunie

# Устанавливаем права
sudo chmod -R 755 /var/www/novolunie
```

### 4. Создание конфигурации Nginx

Создайте файл `/etc/nginx/sites-available/novolunie`:

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    root /var/www/novolunie;
    index index.html;

    # Логи
    access_log /var/log/nginx/novolunie-access.log;
    error_log /var/log/nginx/novolunie-error.log;

    # Основная локация
    location / {
        try_files $uri $uri/ =404;
    }

    # Кеширование статических файлов
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Gzip сжатие
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Безопасность
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
```

### 5. Активация конфигурации

```bash
# Создаем символическую ссылку
sudo ln -s /etc/nginx/sites-available/novolunie /etc/nginx/sites-enabled/

# Проверяем конфигурацию
sudo nginx -t

# Перезагружаем Nginx
sudo systemctl reload nginx
```

### 6. Настройка SSL (Let's Encrypt)

```bash
# Устанавливаем Certbot
sudo apt install certbot python3-certbot-nginx -y

# Получаем SSL сертификат
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Автоматическое обновление сертификата
sudo certbot renew --dry-run
```

После этого Nginx автоматически обновится с HTTPS конфигурацией.

---

## Вариант 2: Python + Gunicorn (если нужен backend)

### 1. Создайте файл `backend/main.py`:

```python
from flask import Flask, send_from_directory
import os

app = Flask(__name__, static_folder='../', static_url_path='')

@app.route('/')
def index():
    return send_from_directory('.', 'index.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
```

### 2. Создайте `requirements.txt`:

```
Flask==3.0.0
gunicorn==21.2.0
```

### 3. Установка на сервере:

```bash
# Устанавливаем Python и зависимости
sudo apt install python3-pip -y
pip3 install -r requirements.txt

# Запускаем через Gunicorn
gunicorn -w 4 -b 0.0.0.0:8000 backend.main:app
```

### 4. Настройка Nginx как reverse proxy:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## Вариант 3: Docker (для изоляции)

### 1. Создайте `Dockerfile`:

```dockerfile
FROM nginx:alpine

# Копируем файлы сайта
COPY . /usr/share/nginx/html

# Копируем конфигурацию Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### 2. Создайте `docker-compose.yml`:

```yaml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
      - ./:/usr/share/nginx/html
    restart: unless-stopped
```

### 3. Запуск:

```bash
docker-compose up -d
```

---

## Быстрый деплой через скрипт

Создайте файл `deploy.sh`:

```bash
#!/bin/bash

SERVER="user@your-server-ip"
REMOTE_PATH="/var/www/novolunie"

echo "Загрузка файлов на сервер..."
rsync -avz --exclude '.git' --exclude 'node_modules' --exclude '*.md' \
  ./ $SERVER:$REMOTE_PATH/

echo "Обновление прав доступа..."
ssh $SERVER "sudo chown -R www-data:www-data $REMOTE_PATH && sudo chmod -R 755 $REMOTE_PATH"

echo "Перезагрузка Nginx..."
ssh $SERVER "sudo nginx -t && sudo systemctl reload nginx"

echo "Готово!"
```

Использование:
```bash
chmod +x deploy.sh
./deploy.sh
```

---

## Проверка после деплоя

1. Откройте сайт в браузере: `http://your-domain.com`
2. Проверьте консоль браузера на ошибки (F12)
3. Проверьте логи Nginx: `sudo tail -f /var/log/nginx/novolunie-error.log`
4. Проверьте доступность всех ресурсов (CSS, JS, изображения)

---

## Полезные команды

```bash
# Проверка статуса Nginx
sudo systemctl status nginx

# Просмотр логов в реальном времени
sudo tail -f /var/log/nginx/novolunie-access.log

# Перезагрузка Nginx
sudo systemctl reload nginx

# Проверка конфигурации
sudo nginx -t
```
