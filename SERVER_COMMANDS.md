# Команды для работы с сервером

## IP сервера: 85.239.44.197

## Быстрые команды

### Применение исправлений Nginx

```bash
# На сервере
cd ~/novolunie
chmod +x apply-nginx-fix.sh
./apply-nginx-fix.sh
```

Или вручную:

```bash
cd ~/novolunie
docker compose down
docker compose up -d --build
docker compose logs -f
```

### Проверка доступности сайта

```bash
# С любого компьютера
curl -I http://85.239.44.197

# Проверка CSS
curl -I http://85.239.44.197/styles/main.css

# Проверка JS
curl -I http://85.239.44.197/js/main.js

# Проверка изображения
curl -I http://85.239.44.197/assets/logo.png
```

### Просмотр логов

```bash
# На сервере
cd ~/novolunie

# Логи контейнера
docker compose logs -f

# Логи Nginx (ошибки)
docker exec novolunie-web tail -f /var/log/nginx/novolunie-error.log

# Логи Nginx (доступ)
docker exec novolunie-web tail -f /var/log/nginx/novolunie-access.log
```

### Проверка статуса

```bash
# Статус контейнера
docker compose ps

# Использование ресурсов
docker stats novolunie-web

# Проверка файлов в контейнере
docker exec novolunie-web ls -la /usr/share/nginx/html/
docker exec novolunie-web ls -la /usr/share/nginx/html/styles/
docker exec novolunie-web ls -la /usr/share/nginx/html/js/
```

### Перезапуск

```bash
# Быстрый перезапуск
docker compose restart

# Полный перезапуск с пересборкой
docker compose down
docker compose up -d --build
```

### Обновление кода

```bash
# Обновить из Git
cd ~/novolunie
git pull

# Пересобрать контейнер
docker compose up -d --build
```

## Диагностика проблем

### Сайт не загружается

```bash
# 1. Проверьте статус
docker compose ps

# 2. Проверьте логи
docker compose logs

# 3. Проверьте порты
sudo netstat -tulpn | grep :80

# 4. Проверьте файрвол
sudo ufw status
```

### CSS/JS не загружаются

```bash
# Проверьте наличие файлов
docker exec novolunie-web ls -la /usr/share/nginx/html/styles/
docker exec novolunie-web ls -la /usr/share/nginx/html/js/

# Проверьте логи ошибок
docker exec novolunie-web tail -50 /var/log/nginx/novolunie-error.log

# Проверьте права доступа
docker exec novolunie-web ls -la /usr/share/nginx/html/
```

### Медленная загрузка

```bash
# Проверьте использование ресурсов
docker stats novolunie-web

# Проверьте логи доступа
docker exec novolunie-web tail -f /var/log/nginx/novolunie-access.log
```

## Полезные ссылки

- Сайт: http://85.239.44.197
- Логи: `docker compose logs -f`
- Статус: `docker compose ps`
