# Решение проблемы Docker Hub Rate Limit

## Проблема

```
failed to solve: nginx:alpine: failed to resolve source metadata for docker.io/library/nginx:alpine: 
failed to copy: httpReadSeeker: failed open: unexpected status from GET request to 
https://registry-1.docker.io/v2/library/nginx/manifests/...: 429 Too Many Requests
```

Docker Hub ограничивает количество запросов для неаутентифицированных пользователей.

## Решение 1: Авторизация в Docker Hub (рекомендуется)

### Шаг 1: Создайте аккаунт на Docker Hub

Перейдите на https://hub.docker.com и создайте бесплатный аккаунт.

### Шаг 2: Авторизуйтесь на сервере

```bash
# Войдите в Docker Hub
docker login

# Введите ваш username и password
```

### Шаг 3: Повторите сборку

```bash
cd ~/novolunie
docker compose up -d --build
```

## Решение 2: Использование альтернативного реестра

Используйте образы из других реестров, которые не имеют таких ограничений.

### Вариант A: Использовать кешированный образ

Если образ уже был скачан ранее:

```bash
# Проверьте, есть ли образ в кеше
docker images | grep nginx

# Если есть, используйте его напрямую
docker pull nginx:alpine || true
```

### Вариант B: Использовать другой базовый образ

Обновите `Dockerfile` для использования образа из другого источника или используйте уже установленный nginx на хосте.

## Решение 3: Использовать Nginx на хосте (быстрое решение)

Вместо Docker контейнера можно использовать Nginx, установленный на хосте:

```bash
# Установите Nginx
sudo apt install -y nginx

# Скопируйте файлы
sudo cp -r ~/novolunie/* /var/www/html/

# Настройте Nginx
sudo nano /etc/nginx/sites-available/novolunie
```

Вставьте конфигурацию из `nginx.conf` в файл конфигурации Nginx.

## Решение 4: Подождать и повторить

Docker Hub сбрасывает лимиты через некоторое время. Подождите 1-6 часов и попробуйте снова.

## Решение 5: Использовать прокси или зеркало

Настройте Docker для использования прокси или зеркала Docker Hub.

## Быстрое решение (рекомендуется)

```bash
# 1. Создайте аккаунт на https://hub.docker.com (если нет)

# 2. Авторизуйтесь
docker login

# 3. Повторите сборку
cd ~/novolunie
docker compose up -d --build
```

После авторизации лимит увеличивается до 200 запросов в 6 часов для бесплатных аккаунтов.
