#!/bin/bash

# Скрипт для настройки Git репозитория

echo "🔧 Настройка Git репозитория для Novolunie..."

# Проверяем, инициализирован ли Git
if [ ! -d ".git" ]; then
    echo "📦 Инициализация Git репозитория..."
    git init
    git branch -M main
else
    echo "✅ Git уже инициализирован"
fi

# Проверяем, есть ли remote
if git remote get-url origin > /dev/null 2>&1; then
    echo "📡 Удаленный репозиторий уже настроен:"
    git remote -v
    read -p "Заменить на https://github.com/som1one/Novolunie-delta.git? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git remote set-url origin https://github.com/som1one/Novolunie-delta.git
        echo "✅ Remote обновлен"
    fi
else
    echo "📡 Добавление удаленного репозитория..."
    git remote add origin https://github.com/som1one/Novolunie-delta.git
    echo "✅ Remote добавлен"
fi

# Добавляем все файлы
echo "📝 Добавление файлов..."
git add .

# Проверяем статус
echo ""
echo "📊 Текущий статус:"
git status --short

echo ""
echo "✅ Готово!"
echo ""
echo "Следующие шаги:"
echo "1. Проверьте изменения: git status"
echo "2. Создайте коммит: git commit -m 'Initial commit: Novolunie website'"
echo "3. Загрузите в репозиторий: git push -u origin main"
