# 🔄 Подтягивание изменений из Git на сервер

## ✅ Простая команда (РЕКОМЕНДУЕТСЯ)

```bash
cd ~/novolunie
git pull origin main
```

---

## 🔧 Если есть конфликты или локальные изменения

### Вариант 1: Отменить все локальные изменения и подтянуть
```bash
cd ~/novolunie
git reset --hard HEAD
git pull origin main
```

### Вариант 2: Сохранить локальные изменения и подтянуть
```bash
cd ~/novolunie
git stash
git pull origin main
git stash pop
```

---

## 📋 Полная последовательность для обновления сайта

### Если используете Nginx (не Docker):

```bash
cd ~/novolunie
git reset --hard HEAD
git pull origin main
sudo cp -r ~/novolunie/* /var/www/html/
sudo systemctl reload nginx
```

### Если используете Docker:

```bash
cd ~/novolunie
git reset --hard HEAD
git pull origin main
docker compose down
docker compose up -d --build
```

---

## 🚀 Быстрый скрипт (одна команда)

Создайте файл `update.sh`:

```bash
#!/bin/bash
cd ~/novolunie
git reset --hard HEAD
git pull origin main

# Если Nginx
if [ -d "/var/www/html" ]; then
    sudo cp -r ~/novolunie/* /var/www/html/
    sudo systemctl reload nginx
fi

# Если Docker
if [ -f "docker-compose.yml" ]; then
    docker compose down
    docker compose up -d --build
fi
```

Использование:
```bash
chmod +x update.sh
./update.sh
```

---

## ⚠️ Важно

- `git reset --hard HEAD` - **удалит все локальные изменения** на сервере
- Используйте его, если уверены, что все изменения уже в Git
- Если есть важные локальные изменения, сначала закоммитьте их или используйте `git stash`

---

## 🔍 Проверка после обновления

```bash
# Проверить, что файлы обновились
ls -lh ~/novolunie/assets/logo.png

# Проверить статус Git
cd ~/novolunie
git status

# Проверить последний коммит
git log -1
```
