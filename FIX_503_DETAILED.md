# 🔧 Детальное исправление ошибки 503

## Ошибка: "503 Service Unavailable - No server is available to handle this request"

Эта ошибка означает, что Nginx не может обработать запрос. Возможные причины:

### 1. Контейнер не запущен
### 2. Nginx внутри контейнера не запущен
### 3. Системный Nginx занимает порт 80
### 4. Проблема с пробросом портов Docker

## Пошаговое исправление

### Шаг 1: Диагностика

```bash
# На сервере выполните диагностику
cd ~/novolunie
chmod +x diagnose-503.sh
./diagnose-503.sh
```

Этот скрипт покажет:
- Статус контейнера
- Занятые порты
- Логи контейнера
- Конфигурацию Nginx
- Доступность сайта

### Шаг 2: Полное исправление

```bash
# Автоматическое исправление
cd ~/novolunie
chmod +x fix-503-complete.sh
./fix-503-complete.sh
```

### Шаг 3: Ручное исправление (если автоматическое не помогло)

#### 3.1. Остановите системный Nginx (если запущен)

```bash
sudo systemctl stop nginx
sudo systemctl disable nginx
sudo systemctl status nginx
```

#### 3.2. Проверьте, что порт 80 свободен

```bash
sudo netstat -tulpn | grep :80
# Или
sudo ss -tulpn | grep :80
```

Если порт занят другим процессом, найдите и остановите его:

```bash
# Найти процесс на порту 80
sudo lsof -i:80
# Или
sudo fuser 80/tcp

# Остановить процесс (замените PID на реальный)
sudo kill -9 <PID>
```

#### 3.3. Обновите код и пересоберите контейнер

```bash
cd ~/novolunie
git pull origin main
docker compose down
docker compose build --no-cache
docker compose up -d
```

#### 3.4. Проверьте статус контейнера

```bash
docker compose ps
```

Должно быть:
```
NAME              STATUS          PORTS
novolunie-web     Up X seconds    0.0.0.0:80->80/tcp
```

#### 3.5. Проверьте логи

```bash
docker compose logs web
```

Ищите ошибки типа:
- `bind() to 0.0.0.0:80 failed (98: Address already in use)`
- `nginx: [emerg] ...`
- `Permission denied`

#### 3.6. Проверьте конфигурацию Nginx внутри контейнера

```bash
docker compose exec web nginx -t
```

Должно быть: `nginx: configuration file /etc/nginx/nginx.conf test is successful`

#### 3.7. Проверьте, что Nginx запущен внутри контейнера

```bash
docker compose exec web ps aux | grep nginx
```

Должны быть процессы:
- `nginx: master process`
- `nginx: worker process`

#### 3.8. Проверьте доступность

```bash
# С сервера
curl -I http://localhost
curl -I http://e-novolunie.ru

# Должен вернуть: HTTP/1.1 200 OK
```

## Частые проблемы и решения

### Проблема 1: Порт 80 занят системным Nginx

**Решение:**
```bash
sudo systemctl stop nginx
sudo systemctl disable nginx
docker compose restart
```

### Проблема 2: Контейнер запущен, но Nginx не отвечает

**Решение:**
```bash
# Проверьте логи
docker compose logs web

# Перезапустите Nginx внутри контейнера
docker compose exec web nginx -s reload

# Или перезапустите контейнер
docker compose restart
```

### Проблема 3: Ошибка в конфигурации Nginx

**Решение:**
```bash
# Проверьте конфигурацию
docker compose exec web nginx -t

# Если ошибка, исправьте nginx.conf и пересоберите
docker compose down
docker compose up -d --build
```

### Проблема 4: Файлы сайта не скопированы в контейнер

**Решение:**
```bash
# Проверьте файлы
docker compose exec web ls -la /usr/share/nginx/html/

# Если файлов нет, пересоберите образ
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Проблема 5: Проблемы с правами доступа

**Решение:**
```bash
# Проверьте права на файлы
ls -la ~/novolunie/

# Установите правильные права
chmod -R 755 ~/novolunie/
chown -R $USER:$USER ~/novolunie/
```

## Проверка после исправления

```bash
# 1. Статус контейнера
docker compose ps

# 2. Логи
docker compose logs --tail=50 web

# 3. Доступность
curl -v http://e-novolunie.ru

# 4. Проверка портов
sudo netstat -tulpn | grep :80

# 5. Проверка DNS
nslookup e-novolunie.ru
```

## Если ничего не помогло

1. **Полная переустановка:**
```bash
cd ~/novolunie
docker compose down -v
docker system prune -f
git pull origin main
docker compose up -d --build
```

2. **Проверьте файрвол:**
```bash
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
```

3. **Проверьте Docker:**
```bash
sudo systemctl status docker
sudo systemctl restart docker
```

4. **Проверьте DNS:**
```bash
# Должен вернуть IP сервера
nslookup e-novolunie.ru
dig e-novolunie.ru +short
```

## Контакты для помощи

Если проблема не решена, соберите информацию:

```bash
cd ~/novolunie
./diagnose-503.sh > diagnosis.txt
cat diagnosis.txt
```

И отправьте содержимое `diagnosis.txt` для анализа.
