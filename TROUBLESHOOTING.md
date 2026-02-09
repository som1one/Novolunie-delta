# Решение проблем с загрузкой сайта

## Проблема: Сайт грузится не у всех пользователей

### Диагностика

```bash
# 1. Проверьте статус контейнера
docker compose ps

# 2. Проверьте логи
docker compose logs -f

# 3. Проверьте доступность портов
sudo netstat -tulpn | grep :80
# или
sudo ss -tulpn | grep :80

# 4. Проверьте файрвол
sudo ufw status

# 5. Проверьте доступность изнутри контейнера
docker exec novolunie-web curl http://localhost

# 6. Проверьте логи Nginx
docker exec novolunie-web tail -f /var/log/nginx/novolunie-error.log
docker exec novolunie-web tail -f /var/log/nginx/novolunie-access.log
```

### Возможные причины и решения

#### 1. Проблема с портами

```bash
# Проверьте, не занят ли порт 80
sudo lsof -i :80

# Если занят другим процессом, остановите его или измените порт в docker-compose.yml
```

#### 2. Проблема с файрволом

```bash
# Убедитесь, что порты открыты
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
```

#### 3. Проблема с DNS/доменом

```bash
# Проверьте DNS записи
nslookup your-domain.com
dig your-domain.com

# Если используете домен, убедитесь что A-запись указывает на IP сервера
```

#### 4. Проблема с кешированием браузера

Пользователи могут видеть старую версию из-за кеша. Решение:
- Обновите конфигурацию Nginx (уже сделано)
- Попросите пользователей сделать жесткую перезагрузку: Ctrl+Shift+R (Windows/Linux) или Cmd+Shift+R (Mac)

#### 5. Проблема с путями к ресурсам

```bash
# Проверьте, что все файлы на месте
docker exec novolunie-web ls -la /usr/share/nginx/html/
docker exec novolunie-web ls -la /usr/share/nginx/html/styles/
docker exec novolunie-web ls -la /usr/share/nginx/html/js/
docker exec novolunie-web ls -la /usr/share/nginx/html/assets/
```

#### 6. Проблема с MIME типами

Если CSS/JS не загружаются, проверьте логи на ошибки MIME типов. Конфигурация уже обновлена.

#### 7. Проблема с CORS (если ресурсы загружаются с другого домена)

Конфигурация уже включает заголовки для шрифтов.

### Быстрое решение

```bash
# 1. Перезапустите контейнер
cd ~/novolunie
docker compose down
docker compose up -d --build

# 2. Проверьте логи
docker compose logs -f

# 3. Проверьте доступность
curl -I http://localhost
curl -I http://your-server-ip
```

### Проверка с разных локаций

```bash
# С сервера
curl -I http://localhost

# С другого сервера/компьютера
curl -I http://your-server-ip

# Проверка DNS (если используете домен)
curl -I http://your-domain.com
```

### Мониторинг в реальном времени

```bash
# Следите за логами доступа
docker exec novolunie-web tail -f /var/log/nginx/novolunie-access.log

# Следите за ошибками
docker exec novolunie-web tail -f /var/log/nginx/novolunie-error.log
```

### Проверка производительности

```bash
# Проверьте использование ресурсов
docker stats novolunie-web

# Проверьте время ответа
time curl http://your-server-ip
```

## Частые ошибки в логах

### 404 Not Found для CSS/JS

**Причина:** Неправильные пути или файлы не скопированы в контейнер

**Решение:**
```bash
# Проверьте структуру файлов
docker exec novolunie-web find /usr/share/nginx/html -type f

# Пересоберите контейнер
docker compose up -d --build
```

### 403 Forbidden

**Причина:** Неправильные права доступа

**Решение:**
```bash
# Проверьте права в Dockerfile
# Файлы должны копироваться с правильными правами
```

### Connection refused

**Причина:** Контейнер не запущен или порт не проброшен

**Решение:**
```bash
docker compose ps
docker compose up -d
```

### Timeout

**Причина:** Файрвол блокирует или сервер перегружен

**Решение:**
```bash
# Проверьте файрвол
sudo ufw status

# Проверьте нагрузку
docker stats
htop
```
