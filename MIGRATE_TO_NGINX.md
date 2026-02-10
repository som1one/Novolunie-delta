# 🚀 Миграция с Docker на чистый Nginx

## Автоматическая миграция

### Быстрый способ:

```bash
cd ~/novolunie
git pull origin main
chmod +x migrate-to-nginx.sh
./migrate-to-nginx.sh
```

Скрипт автоматически:
- ✅ Остановит Docker контейнер
- ✅ Установит Nginx
- ✅ Скопирует файлы сайта
- ✅ Создаст конфигурацию
- ✅ Настроит SSL
- ✅ Откроет порты
- ✅ Запустит Nginx

## Ручная миграция (пошагово)

### Шаг 1: Остановите Docker контейнер

```bash
cd ~/novolunie
docker compose down
```

### Шаг 2: Установите Nginx

```bash
sudo apt update
sudo apt install nginx -y
```

### Шаг 3: Создайте директорию для сайта

```bash
sudo mkdir -p /var/www/e-novolunie.ru
```

### Шаг 4: Скопируйте файлы сайта

```bash
cd ~/novolunie
sudo cp -r index.html styles/ js/ images/ fonts/ /var/www/e-novolunie.ru/

# Установите права
sudo chown -R www-data:www-data /var/www/e-novolunie.ru
sudo chmod -R 755 /var/www/e-novolunie.ru
```

### Шаг 5: Создайте конфигурацию Nginx

```bash
# Скопируйте готовую конфигурацию
sudo cp nginx-static-site.conf /etc/nginx/sites-available/e-novolunie.ru

# Или создайте вручную
sudo nano /etc/nginx/sites-available/e-novolunie.ru
```

Вставьте содержимое из `nginx-static-site.conf`.

### Шаг 6: Активируйте конфигурацию

```bash
# Создайте символическую ссылку
sudo ln -s /etc/nginx/sites-available/e-novolunie.ru /etc/nginx/sites-enabled/

# Удалите дефолтную конфигурацию (если есть)
sudo rm /etc/nginx/sites-enabled/default
```

### Шаг 7: Проверьте конфигурацию

```bash
sudo nginx -t
```

Если есть ошибки, исправьте их.

### Шаг 8: Проверьте SSL сертификаты

```bash
# Проверьте наличие сертификатов
sudo ls -la /etc/letsencrypt/live/e-novolunie.ru/

# Если сертификаты для другого домена, отредактируйте конфигурацию:
sudo nano /etc/nginx/sites-available/e-novolunie.ru

# Или получите новые сертификаты:
sudo certbot --nginx -d e-novolunie.ru -d www.e-novolunie.ru
```

### Шаг 9: Откройте порты в файрволе

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### Шаг 10: Запустите Nginx

```bash
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl status nginx
```

### Шаг 11: Проверьте работу

```bash
# HTTP (должен редиректить на HTTPS)
curl -I http://localhost

# HTTPS
curl -I https://localhost

# Снаружи
curl -I https://e-novolunie.ru
```

## Структура файлов после миграции

```
/var/www/e-novolunie.ru/          # Файлы сайта
├── index.html
├── styles/
├── js/
├── images/
└── fonts/

/etc/nginx/sites-available/       # Доступные конфигурации
└── e-novolunie.ru

/etc/nginx/sites-enabled/         # Активные конфигурации
└── e-novolunie.ru -> ../sites-available/e-novolunie.ru

/var/log/nginx/                   # Логи
├── e-novolunie-access.log
└── e-novolunie-error.log
```

## Полезные команды

### Управление Nginx

```bash
# Статус
sudo systemctl status nginx

# Перезапуск
sudo systemctl restart nginx

# Перезагрузка конфигурации (без остановки)
sudo systemctl reload nginx

# Остановка
sudo systemctl stop nginx

# Запуск
sudo systemctl start nginx
```

### Проверка конфигурации

```bash
# Проверка синтаксиса
sudo nginx -t

# Проверка конфигурации с выводом файлов
sudo nginx -T
```

### Просмотр логов

```bash
# Логи ошибок
sudo tail -f /var/log/nginx/e-novolunie-error.log

# Логи доступа
sudo tail -f /var/log/nginx/e-novolunie-access.log

# Все логи Nginx
sudo journalctl -u nginx -f
```

### Обновление сайта

```bash
# 1. Обновите файлы в проекте
cd ~/novolunie
git pull origin main

# 2. Скопируйте новые файлы
sudo cp -r index.html styles/ js/ images/ fonts/ /var/www/e-novolunie.ru/

# 3. Установите права
sudo chown -R www-data:www-data /var/www/e-novolunie.ru

# 4. Перезагрузите Nginx (если нужно)
sudo systemctl reload nginx
```

## Если что-то пошло не так

### Проблема 1: Nginx не запускается

```bash
# Проверьте логи
sudo journalctl -u nginx -n 50

# Проверьте конфигурацию
sudo nginx -t

# Проверьте, не занят ли порт 80
sudo netstat -tlnp | grep ":80 "
```

### Проблема 2: Ошибка SSL сертификатов

```bash
# Проверьте наличие сертификатов
sudo ls -la /etc/letsencrypt/live/e-novolunie.ru/

# Если сертификаты для другого домена, отредактируйте конфигурацию
sudo nano /etc/nginx/sites-available/e-novolunie.ru

# Или получите новые сертификаты
sudo certbot --nginx -d e-novolunie.ru -d www.e-novolunie.ru
```

### Проблема 3: 403 Forbidden

```bash
# Проверьте права доступа
sudo ls -la /var/www/e-novolunie.ru/

# Установите правильные права
sudo chown -R www-data:www-data /var/www/e-novolunie.ru
sudo chmod -R 755 /var/www/e-novolunie.ru
```

### Проблема 4: 404 Not Found

```bash
# Проверьте, что файлы скопированы
sudo ls -la /var/www/e-novolunie.ru/

# Проверьте конфигурацию root
sudo grep -r "root" /etc/nginx/sites-available/e-novolunie.ru
```

## Возврат к Docker (если нужно)

Если нужно вернуться к Docker:

```bash
# Остановите Nginx
sudo systemctl stop nginx
sudo systemctl disable nginx

# Вернитесь в проект
cd ~/novolunie

# Запустите Docker
docker compose up -d
```

## Преимущества чистого Nginx

- ✅ Проще управление
- ✅ Меньше накладных расходов
- ✅ Прямой доступ к логам
- ✅ Легче отладка
- ✅ Нет зависимости от Docker

## После миграции

1. ✅ Проверьте сайт: https://e-novolunie.ru
2. ✅ Проверьте редирект: http://e-novolunie.ru → https://e-novolunie.ru
3. ✅ Проверьте балансировщик нагрузки (должен видеть порт 80)
4. ✅ Удалите Docker контейнер (если не нужен): `docker compose down`
