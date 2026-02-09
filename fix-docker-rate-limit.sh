#!/bin/bash

# Скрипт для решения проблемы Docker Hub Rate Limit

echo "🔧 Решение проблемы Docker Hub Rate Limit"
echo ""

# Проверяем, авторизован ли пользователь
if docker info 2>&1 | grep -q "Username"; then
    echo "✅ Вы уже авторизованы в Docker Hub"
    docker info | grep Username
else
    echo "⚠️  Вы не авторизованы в Docker Hub"
    echo ""
    echo "Для решения проблемы rate limit нужно авторизоваться:"
    echo ""
    echo "1. Создайте бесплатный аккаунт на https://hub.docker.com (если нет)"
    echo "2. Выполните: docker login"
    echo "3. Введите ваш username и password"
    echo ""
    read -p "Авторизоваться сейчас? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker login
        if [ $? -eq 0 ]; then
            echo "✅ Авторизация успешна!"
        else
            echo "❌ Ошибка авторизации"
            exit 1
        fi
    else
        echo "Пропущено. Выполните 'docker login' вручную перед сборкой."
        exit 0
    fi
fi

echo ""
echo "Теперь можно выполнить сборку:"
echo "cd ~/novolunie && docker compose up -d --build"
