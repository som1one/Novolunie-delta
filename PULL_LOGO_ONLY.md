# 🖼️ Как подтянуть только логотип на сервер

## 🚀 Автоматический способ (РЕКОМЕНДУЕТСЯ)

### Вариант 1: Полный pull + обновление логотипа

```bash
cd ~/novolunie
git pull origin main
chmod +x pull-all-and-update-logo.sh
./pull-all-and-update-logo.sh
```

Скрипт:
1. Сделает полный `git pull` из Git
2. Проверит все изменения
3. Скопирует все файлы на сервер (Docker или Nginx)
4. Обновит логотип
5. Перезагрузит сервис

### Вариант 2: Только логотип

```bash
cd ~/novolunie
git pull origin main
chmod +x pull-logo-only.sh
./pull-logo-only.sh
```

Скрипт:
1. Подтянет изменения из Git
2. Проверит наличие `assets/logo.png`
3. Скопирует в нужное место (Docker или Nginx)
4. Перезагрузит сервис

---

## 📋 Вручную

### Шаг 1: Подтянуть изменения из Git

```bash
cd ~/novolunie
git pull origin main
```

### Шаг 2: Проверить наличие файла

```bash
ls -lh assets/logo.png
```

### Шаг 3: Скопировать на сервер

**Если используете Docker:**
```bash
docker compose down
docker compose up -d --build
```

**Если используете чистый Nginx:**
```bash
sudo mkdir -p /var/www/html/assets
sudo cp assets/logo.png /var/www/html/assets/logo.png
sudo chmod 644 /var/www/html/assets/logo.png
sudo systemctl reload nginx
```

---

## 🎯 Подтянуть только один файл (без pull всего репозитория)

### Вариант 1: Через git checkout

```bash
cd ~/novolunie

# Получить изменения (не применять)
git fetch origin main

# Взять только нужный файл
git checkout origin/main -- assets/logo.png
```

### Вариант 2: Через git show

```bash
cd ~/novolunie

# Скачать файл напрямую из Git
git show origin/main:assets/logo.png > assets/logo.png
```

**Затем скопировать на сервер:**
```bash
# Для Docker
docker compose up -d --build

# Для Nginx
sudo cp assets/logo.png /var/www/html/assets/logo.png
sudo systemctl reload nginx
```

---

## ✅ Проверка

После обновления проверьте:

```bash
# Проверка файла
ls -lh assets/logo.png

# Проверка на сайте
curl -I https://e-novolunie.ru/assets/logo.png
```

Должен вернуть `200 OK`.

---

## 🔄 Быстрая команда (если уже настроен Git)

```bash
cd ~/novolunie && git pull origin main && ./pull-logo-only.sh
```

---

## ⚠️ Если файл не обновляется

### Проверьте, что файл в Git:
```bash
git ls-files assets/logo.png
```

### Проверьте изменения:
```bash
git log --oneline assets/logo.png
```

### Принудительное обновление:
```bash
git fetch origin main
git checkout origin/main -- assets/logo.png
```

---

## 📁 Где находится логотип

- **В репозитории:** `assets/logo.png`
- **На сервере (Nginx):** `/var/www/html/assets/logo.png`
- **В Docker:** внутри контейнера в `/usr/share/nginx/html/assets/logo.png`

---

## 🆘 Если логотип не отображается на сайте

1. **Проверьте путь в HTML:**
   ```bash
   grep -r "logo.png" index.html
   ```
   Должно быть: `src="assets/logo.png"`

2. **Проверьте права доступа:**
   ```bash
   ls -la /var/www/html/assets/logo.png
   ```
   Должно быть: `-rw-r--r--`

3. **Проверьте Nginx конфигурацию:**
   ```bash
   sudo nginx -t
   ```

4. **Проверьте логи:**
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

---

## ✅ Рекомендация

**Используйте скрипт** - он автоматически определит, Docker или Nginx, и скопирует файл в нужное место:

```bash
./pull-logo-only.sh
```
