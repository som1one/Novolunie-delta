# Настройка Git репозитория

## Первоначальная настройка

### 1. Инициализация Git (если еще не инициализирован)

```bash
# Инициализация репозитория
git init

# Добавление удаленного репозитория
git remote add origin https://github.com/som1one/Novolunie-delta.git

# Проверка
git remote -v
```

### 2. Первый коммит и пуш

```bash
# Добавляем все файлы
git add .

# Создаем первый коммит
git commit -m "Initial commit: Novolunie website"

# Переименовываем ветку в main (если нужно)
git branch -M main

# Пушим в репозиторий
git push -u origin main
```

## Работа с репозиторием

### Основные команды

```bash
# Проверка статуса
git status

# Добавление файлов
git add .
git add specific-file.html

# Коммит
git commit -m "Описание изменений"

# Пуш в репозиторий
git push

# Получение изменений
git pull

# Просмотр истории
git log --oneline
```

### Создание новой ветки

```bash
# Создание и переключение на новую ветку
git checkout -b feature/new-feature

# Или (новый синтаксис)
git switch -c feature/new-feature

# Пуш новой ветки
git push -u origin feature/new-feature
```

## Обновление проекта

```bash
# 1. Проверяем изменения
git status

# 2. Добавляем файлы
git add .

# 3. Коммитим
git commit -m "Описание изменений"

# 4. Пушим
git push
```

## Настройка GitHub Actions для автоматического деплоя

### 1. Настройка секретов в GitHub

Перейдите в Settings → Secrets and variables → Actions и добавьте:

- `SERVER_HOST` - IP адрес или домен вашего сервера
- `SERVER_USER` - имя пользователя для SSH (обычно `root` или ваш пользователь)
- `SERVER_SSH_KEY` - приватный SSH ключ для доступа к серверу

### 2. Получение SSH ключа

```bash
# Если ключа нет, создайте его
ssh-keygen -t ed25519 -C "github-actions"

# Скопируйте приватный ключ (для секрета)
cat ~/.ssh/id_ed25519

# Добавьте публичный ключ на сервер
ssh-copy-id user@your-server-ip
```

### 3. Подготовка сервера

На сервере должен быть установлен Docker и настроен доступ по SSH:

```bash
# Установка Docker (если еще не установлен)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Создание директории для проекта
mkdir -p ~/novolunie
cd ~/novolunie

# Клонирование репозитория
git clone https://github.com/som1one/Novolunie-delta.git .
```

### 4. Автоматический деплой

После настройки секретов, каждый push в ветку `main` будет автоматически:
1. Подключаться к серверу по SSH
2. Обновлять код через `git pull`
3. Пересобирать и перезапускать Docker контейнер

См. файл `.github/workflows/deploy.yml` для деталей.
