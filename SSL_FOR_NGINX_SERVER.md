# 🔒 Установка Let's Encrypt SSL для обычного Nginx сервера

## ⚠️ Важно: Это НЕ BitrixVM!

Если у вас **обычный сервер с Nginx** (не BitrixVM), используйте эту инструкцию.

Инструкция для BitrixVM подходит только если у вас установлен BitrixVM 9.

---

## ✅ Для обычного Nginx сервера (ваш случай)

### Способ 1: Автоматический скрипт (РЕКОМЕНДУЕТСЯ)

```bash
cd ~/novolunie
git pull origin main
chmod +x install-ssl-dns.sh
sudo ./install-ssl-dns.sh
```

**Скрипт автоматически:**
1. Установит certbot
2. Получит сертификат Let's Encrypt через DNS challenge
3. Настроит Nginx с HTTPS
4. Скопирует файлы сайта

---

### Способ 2: Вручную через certbot

#### Шаг 1: Установите certbot
```bash
sudo apt update
sudo apt install certbot -y
```

#### Шаг 2: Получите сертификат через DNS challenge
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

#### Шаг 3: Добавьте TXT записи в DNS

Certbot покажет:
```
Please deploy a DNS TXT record:
_acme-challenge.e-novolunie.ru
Значение: 00XvlVkxaIwO-aCcozQWZKvu54777yN1QGY9x7LZERg
```

**Что делать:**
1. Откройте https://timeweb.cloud
2. **Домены** → **e-novolunie.ru** → **DNS**
3. Добавьте TXT запись:
   - **Тип:** TXT
   - **Имя:** `_acme-challenge` (или `_acme-challenge.e-novolunie.ru`)
   - **Значение:** (скопируйте из certbot)
4. Сохраните
5. Подождите 2-5 минут
6. Вернитесь в терминал и нажмите **Enter**

#### Шаг 4: Сертификат будет сохранен в
```
/etc/letsencrypt/live/e-novolunie.ru/
├── fullchain.pem  ← используйте в Nginx
├── privkey.pem    ← используйте в Nginx
├── chain.pem
└── cert.pem
```

#### Шаг 5: Настройте Nginx

Создайте конфигурацию `/etc/nginx/sites-available/e-novolunie.ru`:

```nginx
# HTTP - редирект на HTTPS
server {
    listen 80;
    server_name e-novolunie.ru www.e-novolunie.ru;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS
server {
    listen 443 ssl http2;
    server_name e-novolunie.ru www.e-novolunie.ru;

    ssl_certificate /etc/letsencrypt/live/e-novolunie.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/e-novolunie.ru/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

Активируйте:
```bash
sudo ln -sf /etc/nginx/sites-available/e-novolunie.ru /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔄 Автоматическое обновление (как в BitrixVM)

Let's Encrypt сертификаты действительны **90 дней**. Настройте автообновление:

### Проверка автообновления
```bash
sudo certbot renew --dry-run
```

### Настройка через cron (автоматическое обновление)
```bash
sudo crontab -e
```

Добавьте строку:
```cron
0 0 1 * * certbot renew --quiet && systemctl reload nginx
```

Это будет обновлять сертификат **каждый месяц** и перезагружать Nginx.

---

## 📋 Сравнение методов

| Метод | Для кого | Сложность |
|-------|----------|-----------|
| **BitrixVM** | Только для BitrixVM 9 | Просто (через меню) |
| **Certbot (ваш случай)** | Обычный Nginx сервер | Средне (команды) |
| **Скрипт install-ssl-dns.sh** | Обычный Nginx сервер | Просто (автоматически) |

---

## ✅ Рекомендация

**Используйте скрипт** - он делает всё автоматически, как BitrixVM:

```bash
sudo ./install-ssl-dns.sh
```

---

## 🆘 Если что-то пошло не так

### Certbot не может получить сертификат
```bash
# Проверьте логи
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# Проверьте DNS
dig TXT _acme-challenge.e-novolunie.ru
```

### Nginx не запускается
```bash
# Проверьте конфигурацию
sudo nginx -t

# Проверьте логи
sudo tail -f /var/log/nginx/error.log
```

---

## 📚 Полезные ссылки

- Let's Encrypt: https://letsencrypt.org
- Certbot документация: https://eff-certbot.readthedocs.io/
- Timeweb Cloud SSL: https://timeweb.cloud/docs/ssl/installing-ssl
