# 🔒 Установка SSL сертификата вручную на сервере

## 📋 Ответ поддержки Timeweb

> "Для существующего балансировщика выпуск и установка SSL происходит вручную на вашем сервере. Привяжите домен к серверу напрямую по A-записи и выпустите сертификат."

**Источник:** [Документация Timeweb Cloud](https://timeweb.cloud/docs/ssl/installing-ssl#ustanovka-ssl-sertifikata-vruchnuu)

---

## ⚠️ Важно: Два варианта установки

### Вариант 1: DNS Challenge (РЕКОМЕНДУЕТСЯ) ✅
- **Не требует изменения A-записи**
- Работает даже с балансировщиком
- Не нарушает работу сайта
- Нужно добавить TXT записи в DNS

### Вариант 2: HTTP Challenge (через A-запись)
- Требует временного изменения A-записи на IP сервера
- Балансировщик временно не будет работать
- Проще в настройке

---

## 🚀 Вариант 1: DNS Challenge (БЕЗ изменения A-записи)

### Шаг 1: Подключитесь к серверу
```bash
ssh root@ваш_сервер
cd ~/novolunie
```

### Шаг 2: Установите certbot (если не установлен)
```bash
sudo apt update
sudo apt install certbot -y
```

### Шаг 3: Получите сертификат через DNS challenge
```bash
sudo certbot certonly --manual --preferred-challenges dns \
  -d e-novolunie.ru -d www.e-novolunie.ru \
  --register-unsafely-without-email --agree-tos
```

**Или с email:**
```bash
sudo certbot certonly --manual --preferred-challenges dns \
  -d e-novolunie.ru -d www.e-novolunie.ru \
  --email ваш@email.com --agree-tos
```

### Шаг 4: Добавьте TXT записи в DNS

Certbot покажет что-то вроде:
```
Please deploy a DNS TXT record under the name:
_acme-challenge.e-novolunie.ru.

with the following value:
00XvlVkxaIwO-aCcozQWZKvu54777yN1QGY9x7LZERg
```

**Что делать:**
1. Откройте панель управления доменом в Timeweb Cloud
2. Перейдите: **Домены** → **e-novolunie.ru** → **DNS**
3. Добавьте TXT запись:
   - **Тип:** TXT
   - **Имя:** `_acme-challenge.e-novolunie.ru` (или `_acme-challenge`)
   - **Значение:** (значение из certbot)
4. Повторите для `www.e-novolunie.ru` (если certbot попросит)
5. Подождите 2-5 минут для распространения DNS
6. Нажмите **Enter** в терминале certbot

### Шаг 5: Проверьте получение сертификата
```bash
sudo ls -la /etc/letsencrypt/live/e-novolunie.ru/
```

Должны быть файлы:
- `fullchain.pem` - полная цепочка сертификатов
- `privkey.pem` - приватный ключ
- `chain.pem` - промежуточный сертификат
- `cert.pem` - сертификат

### Шаг 6: Настройте Nginx с HTTPS

Используйте готовый скрипт:
```bash
cd ~/novolunie
git pull origin main
chmod +x setup-nginx-https.sh
./setup-nginx-https.sh
```

**Или настройте вручную** (см. раздел ниже)

---

## 🔧 Вариант 2: HTTP Challenge (с изменением A-записи)

### ⚠️ ВНИМАНИЕ: Сайт будет недоступен во время установки!

### Шаг 1: Узнайте IP вашего сервера
```bash
curl ifconfig.me
# Или
hostname -I
```

### Шаг 2: Измените A-запись домена
1. Откройте панель Timeweb Cloud
2. **Домены** → **e-novolunie.ru** → **DNS**
3. Найдите A-запись для `e-novolunie.ru`
4. Измените значение на **IP вашего сервера**
5. Сохраните изменения
6. Подождите 5-10 минут для распространения DNS

### Шаг 3: Получите сертификат
```bash
sudo certbot certonly --standalone \
  -d e-novolunie.ru -d www.e-novolunie.ru \
  --register-unsafely-without-email --agree-tos
```

### Шаг 4: Настройте Nginx (см. ниже)

### Шаг 5: Верните A-запись на балансировщик (если нужно)
После установки SSL можете вернуть A-запись на IP балансировщика.

---

## ⚙️ Настройка Nginx с HTTPS

### Создайте конфигурацию Nginx

```bash
sudo nano /etc/nginx/sites-available/e-novolunie.ru
```

**Вставьте:**
```nginx
# HTTP сервер - редирект на HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name e-novolunie.ru www.e-novolunie.ru;

    # Разрешаем доступ к ACME challenge для обновления сертификатов
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files $uri =404;
    }

    # Редирект на HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS сервер
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name e-novolunie.ru www.e-novolunie.ru;

    # SSL сертификаты
    ssl_certificate /etc/letsencrypt/live/e-novolunie.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/e-novolunie.ru/privkey.pem;

    # SSL настройки
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Корневая директория сайта
    root /var/www/html;
    index index.html;

    # Логи
    access_log /var/log/nginx/e-novolunie.ru.access.log;
    error_log /var/log/nginx/e-novolunie.ru.error.log;

    # Основная конфигурация
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Кэширование статических файлов
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Gzip сжатие
    gzip on;
    gzip_vary on;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Безопасность
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Обработка ошибок
    error_page 404 /index.html;
    error_page 500 502 503 504 /index.html;

    server_tokens off;
    client_max_body_size 10M;
}
```

### Активируйте конфигурацию
```bash
sudo ln -sf /etc/nginx/sites-available/e-novolunie.ru /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Скопируйте файлы сайта
```bash
sudo cp -r ~/novolunie/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html
```

---

## ✅ Проверка работы HTTPS

```bash
# Проверка HTTP редиректа
curl -I http://e-novolunie.ru

# Проверка HTTPS
curl -I https://e-novolunie.ru

# Проверка сертификата
openssl s_client -connect e-novolunie.ru:443 -servername e-novolunie.ru < /dev/null
```

---

## 🔄 Автоматическое обновление сертификатов

Let's Encrypt сертификаты действительны 90 дней. Настройте автообновление:

```bash
# Проверка автообновления
sudo certbot renew --dry-run

# Добавьте в crontab (обновление раз в месяц)
sudo crontab -e
# Добавьте строку:
0 0 1 * * certbot renew --quiet && systemctl reload nginx
```

---

## 🆘 Если что-то пошло не так

### Сертификат не получен
```bash
# Проверьте логи
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# Попробуйте снова с DNS challenge
sudo certbot certonly --manual --preferred-challenges dns \
  -d e-novolunie.ru -d www.e-novolunie.ru \
  --register-unsafely-without-email --agree-tos
```

### Nginx не запускается
```bash
# Проверьте конфигурацию
sudo nginx -t

# Проверьте логи
sudo tail -f /var/log/nginx/error.log
```

### Сайт не открывается по HTTPS
```bash
# Проверьте, слушает ли Nginx порт 443
sudo netstat -tlnp | grep 443

# Проверьте файрвол
sudo ufw status
sudo ufw allow 443/tcp
```

---

## 📚 Полезные ссылки

- [Документация Timeweb Cloud - Установка SSL](https://timeweb.cloud/docs/ssl/installing-ssl#ustanovka-ssl-sertifikata-vruchnuu)
- [Документация Certbot](https://eff-certbot.readthedocs.io/)

---

## 🎯 Рекомендация

**Используйте Вариант 1 (DNS Challenge)** - он не нарушает работу балансировщика и сайта.
