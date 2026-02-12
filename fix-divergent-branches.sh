#!/bin/bash

# Скрипт для исправления divergent branches на сервере

echo "🔧 Исправление divergent branches"
echo "=================================="
echo ""

cd ~/novolunie || exit 1

echo "1️⃣ Проверка текущего состояния..."
git status

echo ""
echo "2️⃣ Сохранение текущего состояния (на всякий случай)..."
BACKUP_DIR="/tmp/novolunie-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r . "$BACKUP_DIR/" 2>/dev/null || true
echo "✅ Резервная копия создана: $BACKUP_DIR"

echo ""
echo "3️⃣ Отмена локальных изменений и подтягивание из Git..."
git reset --hard HEAD
git pull origin main

if [ $? -ne 0 ]; then
    echo ""
    echo "⚠️  Ошибка при pull. Пробуем через merge..."
    git config pull.rebase false
    git pull origin main
fi

if [ $? -ne 0 ]; then
    echo ""
    echo "⚠️  Ошибка при pull. Пробуем через rebase..."
    git config pull.rebase true
    git pull origin main
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Успешно подтянуто из Git!"
    echo ""
    echo "4️⃣ Проверка статуса..."
    git status
else
    echo ""
    echo "❌ Ошибка при подтягивании из Git"
    echo ""
    echo "Попробуйте вручную:"
    echo "  git fetch origin main"
    echo "  git reset --hard origin/main"
    exit 1
fi

echo ""
echo "✅ Готово!"
