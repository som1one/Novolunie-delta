# Команды для обновления на сервере

## Быстрое обновление (рекомендуется)

```bash
# На сервере выполните:
cd ~/novolunie
chmod +x UPDATE_SERVER.sh
./UPDATE_SERVER.sh
```

## Обновление вручную

```bash
# 1. Подключитесь к серверу
ssh user@85.239.44.197

# 2. Перейдите в директорию проекта
cd ~/novolunie

# 3. Получите обновления из Git
git pull origin main

# 4. Пересоберите контейнер
docker compose down
docker compose up -d --build

# 5. Проверьте статус
docker compose ps

# 6. Проверьте логи
docker compose logs -f
```

## Проверка обновлений

```bash
# Проверьте, что код обновился
cd ~/novolunie
git log --oneline -5

# Проверьте статус контейнера
docker compose ps

# Проверьте доступность сайта
curl -I http://85.239.44.197
```

## Если возникли проблемы

```bash
# Откатите изменения (если нужно)
cd ~/novolunie
git reset --hard HEAD~1
docker compose up -d --build

# Или вернитесь к конкретному коммиту
git reset --hard <commit-hash>
docker compose up -d --build
```

## Автоматическое обновление (через cron)

Добавьте в crontab для автоматического обновления:

```bash
# Редактируйте crontab
crontab -e

# Добавьте строку для обновления каждый день в 3:00
0 3 * * * cd ~/novolunie && git pull origin main && docker compose up -d --build
```
