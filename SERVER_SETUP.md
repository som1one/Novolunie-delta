# Настройка пустого сервера Ubuntu

## Шаг 1: Подключение к серверу

```bash
# Подключитесь к серверу по SSH
ssh root@your-server-ip
# или
ssh user@your-server-ip
```

## Шаг 2: Обновление системы

```bash
# Обновляем список пакетов
sudo apt update

# Обновляем систему
sudo apt upgrade -y

# Устанавливаем базовые утилиты
sudo apt install -y curl wget git nano ufw
```

## Шаг 3: Установка Docker

```bash
# Удаляем старые версии (если есть)
sudo apt remove -y docker docker-engine docker.io containerd runc

# Устанавливаем зависимости
sudo apt install -y ca-certificates curl gnupg lsb-release

# Добавляем официальный GPG ключ Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Добавляем репозиторий Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Обновляем список пакетов
sudo apt update

# Устанавливаем Docker
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Проверяем установку
docker --version
docker compose version

# Добавляем текущего пользователя в группу docker (чтобы не использовать sudo)
sudo usermod -aG docker $USER
newgrp docker

# Проверяем работу Docker
docker run hello-world
```

## Шаг 4: Настройка файрвола (опционально, но рекомендуется)

```bash
# Разрешаем SSH
sudo ufw allow 22/tcp

# Разрешаем HTTP и HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Включаем файрвол
sudo ufw enable

# Проверяем статус
sudo ufw status
```

## Шаг 5: Создание пользователя для проекта (опционально)

```bash
# Создаем нового пользователя (если нужно)
sudo adduser novolunie
sudo usermod -aG docker novolunie
sudo usermod -aG sudo novolunie

# Переключаемся на нового пользователя
su - novolunie
```

## Шаг 6: Клонирование репозитория

```bash
# Создаем директорию для проекта
mkdir -p ~/novolunie
cd ~/novolunie

# Клонируем репозиторий
git clone https://github.com/som1one/Novolunie-delta.git .

# Или если репозиторий еще пустой, создаем структуру вручную
# (загрузите файлы через scp/rsync с локального компьютера)
```

## Шаг 7: Загрузка файлов (если репозиторий пустой)

**С вашего локального компьютера:**

```bash
# Через scp
scp -r * user@your-server-ip:~/novolunie/

# Или через rsync (лучше)
rsync -avz --exclude '.git' --exclude 'node_modules' \
  ./ user@your-server-ip:~/novolunie/
```

## Шаг 8: Авторизация в Docker Hub (важно!)

**⚠️ ВАЖНО:** Docker Hub ограничивает количество запросов для неаутентифицированных пользователей. Авторизуйтесь перед сборкой:

```bash
# Авторизуйтесь в Docker Hub
docker login

# Введите ваш username и password
# Если нет аккаунта, создайте на https://hub.docker.com (бесплатно)
```

## Шаг 9: Запуск Docker контейнера

```bash
# Переходим в директорию проекта
cd ~/novolunie

# Проверяем наличие docker-compose.yml
ls -la docker-compose.yml

# Собираем и запускаем контейнер
docker compose up -d --build

# Проверяем статус
docker compose ps

# Смотрим логи
docker compose logs -f
```

**Если получили ошибку 429 Too Many Requests:**
- См. [DOCKER_RATE_LIMIT_FIX.md](DOCKER_RATE_LIMIT_FIX.md) для решения проблемы

## Шаг 9: Проверка работы

```bash
# Проверяем, что контейнер запущен
docker ps

# Проверяем доступность сайта
curl http://localhost

# Или откройте в браузере
# http://your-server-ip
```

## Шаг 10: Настройка домена и SSL (опционально)

### Вариант A: Nginx на хосте + Let's Encrypt

```bash
# Устанавливаем Nginx
sudo apt install -y nginx certbot python3-certbot-nginx

# Создаем конфиг для домена
sudo nano /etc/nginx/sites-available/novolunie
```

Вставьте следующую конфигурацию:

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

```bash
# Активируем конфиг
sudo ln -s /etc/nginx/sites-available/novolunie /etc/nginx/sites-enabled/

# Проверяем конфигурацию
sudo nginx -t

# Перезагружаем Nginx
sudo systemctl reload nginx

# Получаем SSL сертификат
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Проверяем автообновление сертификата
sudo certbot renew --dry-run
```

## Шаг 11: Настройка автозапуска (systemd)

Создайте файл `/etc/systemd/system/novolunie.service`:

```bash
sudo nano /etc/systemd/system/novolunie.service
```

Вставьте:

```ini
[Unit]
Description=Novolunie Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/novolunie/novolunie
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

```bash
# Перезагружаем systemd
sudo systemctl daemon-reload

# Включаем автозапуск
sudo systemctl enable novolunie.service

# Запускаем сервис
sudo systemctl start novolunie.service

# Проверяем статус
sudo systemctl status novolunie.service
```

## Полезные команды для управления

```bash
# Остановить контейнер
docker compose down

# Перезапустить
docker compose restart

# Пересобрать и перезапустить
docker compose up -d --build

# Посмотреть логи
docker compose logs -f

# Очистить неиспользуемые образы
docker system prune -a

# Обновить проект из Git
cd ~/novolunie
git pull
docker compose up -d --build
```

## Проверка всех сервисов

```bash
# Статус Docker
sudo systemctl status docker

# Статус контейнера
docker compose ps

# Статус systemd сервиса (если настроен)
sudo systemctl status novolunie.service

# Статус Nginx (если установлен)
sudo systemctl status nginx
```

## Troubleshooting

### Проблема: Docker требует sudo

```bash
# Добавьте пользователя в группу docker
sudo usermod -aG docker $USER
newgrp docker
```

### Проблема: Порт 80 уже занят

```bash
# Проверьте, что занимает порт
sudo lsof -i :80

# Или измените порт в docker-compose.yml
# ports:
#   - "8080:80"
```

### Проблема: Контейнер не запускается

```bash
# Проверьте логи
docker compose logs

# Проверьте конфигурацию
docker compose config
```

### Проблема: Нет доступа к файлам

```bash
# Проверьте права
ls -la

# Исправьте права
chmod -R 755 ~/novolunie
```
