# Деплой через Docker

## Быстрый старт

### 1. Установка Docker на сервере

```bash
# Обновляем систему
sudo apt update && sudo apt upgrade -y

# Устанавливаем Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Устанавливаем Docker Compose
sudo apt install docker-compose-plugin -y

# Добавляем пользователя в группу docker (чтобы не использовать sudo)
sudo usermod -aG docker $USER
newgrp docker

# Проверяем установку
docker --version
docker compose version
```

### 2. Подготовка файлов на сервере

```bash
# Создаем директорию для проекта
mkdir -p ~/novolunie
cd ~/novolunie

# Загружаем файлы с локального компьютера
# С вашего компьютера выполните:
scp -r * user@your-server-ip:~/novolunie/
```

### 3. Запуск контейнера

```bash
cd ~/novolunie

# Собираем и запускаем контейнер
docker compose up -d --build

# Проверяем статус
docker compose ps

# Смотрим логи
docker compose logs -f
```

### 4. Проверка работы

Откройте в браузере: `http://your-server-ip`

---

## Настройка домена и SSL

### Вариант 1: Nginx на хосте + Docker (рекомендуется)

На хосте устанавливаем Nginx как reverse proxy:

```bash
sudo apt install nginx certbot python3-certbot-nginx -y
```

Создаем конфиг `/etc/nginx/sites-available/novolunie`:

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Активируем и настраиваем SSL:

```bash
sudo ln -s /etc/nginx/sites-available/novolunie /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

### Вариант 2: Traefik (автоматический SSL)

Создайте `docker-compose.traefik.yml`:

```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.email=your-email@example.com"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./letsencrypt:/letsencrypt
    restart: unless-stopped

  web:
    build: .
    container_name: novolunie-web
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.novolunie.rule=Host(`your-domain.com`)"
      - "traefik.http.routers.novolunie.entrypoints=websecure"
      - "traefik.http.routers.novolunie.tls.certresolver=letsencrypt"
      - "traefik.http.routers.novolunie.entrypoints=web"
      - "traefik.http.routers.novolunie-redirect.rule=Host(`your-domain.com`)"
      - "traefik.http.routers.novolunie-redirect.entrypoints=web"
      - "traefik.http.routers.novolunie-redirect.middlewares=redirect-to-https"
      - "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"
    restart: unless-stopped
    networks:
      - novolunie-network

networks:
  novolunie-network:
    driver: bridge
```

Запуск:

```bash
docker compose -f docker-compose.traefik.yml up -d --build
```

---

## Полезные команды

```bash
# Остановить контейнер
docker compose down

# Перезапустить
docker compose restart

# Пересобрать и перезапустить
docker compose up -d --build

# Посмотреть логи
docker compose logs -f web

# Войти в контейнер
docker exec -it novolunie-web sh

# Очистить все (осторожно!)
docker compose down -v
docker system prune -a
```

---

## Обновление сайта

### Способ 1: Пересборка образа

```bash
# На сервере
cd ~/novolunie

# Загружаете новые файлы (через scp/rsync)
# Затем:
docker compose up -d --build
```

### Способ 2: Автоматический деплой через скрипт

Создайте `deploy-docker.sh`:

```bash
#!/bin/bash

SERVER="user@your-server-ip"
REMOTE_PATH="~/novolunie"

echo "🚀 Деплой через Docker..."

# Загрузка файлов
rsync -avz --exclude '.git' --exclude 'node_modules' \
  ./ $SERVER:$REMOTE_PATH/

# Пересборка на сервере
ssh $SERVER "cd $REMOTE_PATH && docker compose up -d --build"

echo "✅ Готово!"
```

---

## Мониторинг и логи

```bash
# Логи в реальном времени
docker compose logs -f

# Использование ресурсов
docker stats novolunie-web

# Проверка здоровья контейнера
docker inspect novolunie-web | grep Health
```

---

## Резервное копирование

```bash
# Сохранить образ
docker save novolunie-web:latest | gzip > novolunie-backup.tar.gz

# Восстановить
docker load < novolunie-backup.tar.gz
```

---

## Troubleshooting

### Контейнер не запускается

```bash
# Проверьте логи
docker compose logs web

# Проверьте конфигурацию
docker compose config
```

### Порт уже занят

```bash
# Измените порты в docker-compose.yml
ports:
  - "8080:80"  # Вместо 80:80
```

### Проблемы с правами

```bash
# Проверьте права на файлы
ls -la

# Исправьте при необходимости
chmod -R 755 .
```
