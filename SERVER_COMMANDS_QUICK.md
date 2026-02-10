# 🚀 Быстрые команды для сервера

## Обновление проекта из Git (если есть конфликты)

### Быстрое исправление (отменить локальные изменения):

```bash
cd ~/novolunie
git reset --hard HEAD
git pull origin main
chmod +x *.sh
```

⚠️ **ВАЖНО:** Если Git не может обновиться, всегда используйте `git reset --hard HEAD` перед `git pull`

### Или используйте скрипт:

```bash
cd ~/novolunie
git reset --hard HEAD
git pull origin main
chmod +x update-from-git.sh
./update-from-git.sh
```

## Миграция с Docker на чистый Nginx

### Автоматический способ:

```bash
cd ~/novolunie
git pull origin main
chmod +x migrate-to-nginx.sh
./migrate-to-nginx.sh
```

### Получение SSL сертификатов через Certbot

### Автоматический способ (рекомендуется):

```bash
cd ~/novolunie
git pull origin main
chmod +x get-ssl-certificates.sh
./get-ssl-certificates.sh
```

Скрипт автоматически получит сертификаты и настроит HTTPS.

### Ручной способ:

```bash
# Установите certbot
sudo apt update
sudo apt install certbot python3-certbot-nginx -y

# Получите сертификаты (укажите свой email)
sudo certbot --nginx -d e-novolunie.ru -d www.e-novolunie.ru

# Или без email (не рекомендуется)
sudo certbot --nginx -d e-novolunie.ru -d www.e-novolunie.ru --register-unsafely-without-email --agree-tos --non-interactive
```

## Настройка HTTPS (если сертификаты уже есть)

### Автоматический способ:

```bash
cd ~/novolunie
git pull origin main
chmod +x setup-nginx-https.sh
./setup-nginx-https.sh
```

Скрипт автоматически найдет SSL сертификаты и настроит HTTPS.

## Проверка статуса Nginx и сайта

### Полная проверка:

```bash
cd ~/novolunie
git pull origin main
chmod +x check-nginx-status.sh
./check-nginx-status.sh
```

### Быстрая проверка:

```bash
# Статус Nginx
sudo systemctl status nginx

# Проверка конфигурации
sudo nginx -t

# Проверка портов
sudo netstat -tlnp | grep -E ":(80|443) "

# Проверка доступности
curl -I http://localhost
curl -I https://localhost
```

## После миграции - обновление сайта:

```bash
cd ~/novolunie
git pull origin main
sudo cp -r index.html styles/ js/ images/ fonts/ /var/www/e-novolunie.ru/
sudo chown -R www-data:www-data /var/www/e-novolunie.ru
sudo systemctl reload nginx
```

## Обновление сайта из Git (Docker)

```bash
# Подключитесь к серверу
ssh user@85.239.44.197

# Выполните эти команды:
cd ~/novolunie
git pull origin main
docker compose down
docker compose up -d --build
docker compose ps
```

## Или используйте скрипт:

```bash
cd ~/novolunie
chmod +x UPDATE_SERVER.sh
./UPDATE_SERVER.sh
```

## Проверка работы

```bash
# Проверьте сайт
curl -I http://85.239.44.197

# Проверьте логи
docker compose logs -f
```

## Открытие портов 80 и 443

### Автоматический способ:

```bash
cd ~/novolunie
git pull origin main
chmod +x open-ports.sh
./open-ports.sh
```

### Ручной способ (UFW):

```bash
# Откройте порты в файрволе
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Проверьте
sudo ufw status numbered
```

## Диагностика: Порты 80 и 443 недоступны

### Полная диагностика:

```bash
cd ~/novolunie
git pull origin main
chmod +x diagnose-ports.sh
./diagnose-ports.sh
```

### Быстрое исправление:

```bash
# 1. Откройте порты в UFW
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 2. Остановите системный Nginx (если мешает)
sudo systemctl stop nginx
sudo systemctl disable nginx

# 3. Перезапустите контейнер
cd ~/novolunie
docker compose restart

# 4. Проверьте
curl -I http://localhost
sudo netstat -tlnp | grep -E ":(80|443) "
```

⚠️ **ВАЖНО:** Если порты всё ещё недоступны, проверьте файрвол провайдера в панели управления!

## Исправление: Сервер исключен из балансировки (порт 80)

```bash
cd ~/novolunie
git pull origin main
chmod +x fix-port-80.sh
./fix-port-80.sh
```

### Или вручную:

```bash
# 1. Откройте порты в файрволе
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 2. Остановите системный Nginx (если запущен)
sudo systemctl stop nginx
sudo systemctl disable nginx

# 3. Перезапустите контейнер
cd ~/novolunie
docker compose restart

# 4. Проверьте
curl -I http://localhost
docker compose ps
```

---

**IP сервера:** 85.239.44.197  
**Домен:** e-novolunie.ru  
**Репозиторий:** https://github.com/som1one/Novolunie-delta.git
