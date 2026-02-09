# Просмотр логов Docker контейнера

## Основные команды

### Просмотр логов в реальном времени

```bash
# Логи всех сервисов
docker compose logs -f

# Логи конкретного сервиса (web)
docker compose logs -f web

# Логи контейнера по имени
docker logs -f novolunie-web
```

### Просмотр последних записей

```bash
# Последние 50 строк
docker compose logs --tail=50

# Последние 100 строк
docker compose logs --tail=100

# Последние 50 строк конкретного сервиса
docker compose logs --tail=50 web
```

### Просмотр логов с временными метками

```bash
# С временными метками
docker compose logs -f -t

# С временными метками, последние 100 строк
docker compose logs --tail=100 -t
```

### Просмотр логов за определенный период

```bash
# Логи за последний час
docker compose logs --since 1h

# Логи за последние 30 минут
docker compose logs --since 30m

# Логи с определенного времени
docker compose logs --since "2024-01-01T00:00:00"
```

### Сохранение логов в файл

```bash
# Сохранить логи в файл
docker compose logs > logs.txt

# Сохранить с временными метками
docker compose logs -t > logs-with-timestamps.txt

# Добавить к существующему файлу
docker compose logs >> logs.txt
```

## Полезные команды для диагностики

```bash
# Статус контейнера
docker compose ps

# Детальная информация о контейнере
docker inspect novolunie-web

# Использование ресурсов
docker stats novolunie-web

# События контейнера
docker events --filter container=novolunie-web

# Войти в контейнер (для отладки)
docker exec -it novolunie-web sh
```

## Просмотр логов Nginx внутри контейнера

```bash
# Войти в контейнер
docker exec -it novolunie-web sh

# Просмотр логов Nginx
tail -f /var/log/nginx/novolunie-access.log
tail -f /var/log/nginx/novolunie-error.log

# Или извне
docker exec novolunie-web tail -f /var/log/nginx/novolunie-access.log
docker exec novolunie-web tail -f /var/log/nginx/novolunie-error.log
```

## Быстрые команды для копирования

```bash
# Самые частые команды:
docker compose logs -f                    # Логи в реальном времени
docker compose logs --tail=100            # Последние 100 строк
docker compose logs -f -t web              # Логи с временем для сервиса web
docker compose ps                          # Статус контейнеров
```
