#!/bin/bash

# Скрипт для настройки аутентификации Git на сервере

echo "🔐 Настройка аутентификации Git"
echo "================================"
echo ""

cd ~/novolunie || exit 1

echo "Выберите способ аутентификации:"
echo ""
echo "1) Personal Access Token (проще, быстрее)"
echo "2) SSH ключ (безопаснее, не нужно вводить токен)"
echo ""
read -p "Выберите (1 или 2): " AUTH_METHOD

if [ "$AUTH_METHOD" = "1" ]; then
    echo ""
    echo "📝 Настройка через Personal Access Token"
    echo "=========================================="
    echo ""
    echo "1. Откройте в браузере:"
    echo "   https://github.com/settings/tokens"
    echo ""
    echo "2. Нажмите 'Generate new token' → 'Generate new token (classic)'"
    echo ""
    echo "3. Настройки токена:"
    echo "   - Note: Novolunie Server"
    echo "   - Expiration: 90 days (или No expiration)"
    echo "   - Scopes: отметьте 'repo' (все подразделы)"
    echo ""
    echo "4. Нажмите 'Generate token'"
    echo "5. СКОПИРУЙТЕ токен (он показывается только один раз!)"
    echo ""
    read -p "Вставьте токен сюда: " GITHUB_TOKEN
    
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "❌ Токен не введен!"
        exit 1
    fi
    
    echo ""
    echo "Настройка Git..."
    git remote set-url origin https://${GITHUB_TOKEN}@github.com/som1one/Novolunie-delta.git
    
    echo ""
    echo "✅ Настроено! Теперь можно пушить:"
    echo "   git push origin main"
    echo ""
    echo "⚠️  ВАЖНО: Токен сохранен в URL. Для безопасности:"
    echo "   - Не делитесь этим токеном"
    echo "   - Если токен скомпрометирован, удалите его в GitHub"
    
elif [ "$AUTH_METHOD" = "2" ]; then
    echo ""
    echo "🔑 Настройка через SSH ключ"
    echo "============================"
    echo ""
    
    # Проверяем, есть ли уже SSH ключ
    if [ -f ~/.ssh/id_ed25519.pub ]; then
        echo "✅ SSH ключ уже существует!"
        echo ""
        echo "Ваш публичный ключ:"
        cat ~/.ssh/id_ed25519.pub
        echo ""
        echo "Скопируйте этот ключ и добавьте в GitHub:"
        echo "   https://github.com/settings/ssh/new"
        echo ""
        read -p "Нажмите Enter после добавления ключа в GitHub..."
    else
        echo "Создание SSH ключа..."
        read -p "Введите email (или нажмите Enter для пропуска): " SSH_EMAIL
        
        if [ -z "$SSH_EMAIL" ]; then
            ssh-keygen -t ed25519 -C "novolunie-server" -f ~/.ssh/id_ed25519 -N ""
        else
            ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f ~/.ssh/id_ed25519 -N ""
        fi
        
        echo ""
        echo "✅ SSH ключ создан!"
        echo ""
        echo "Ваш публичный ключ:"
        cat ~/.ssh/id_ed25519.pub
        echo ""
        echo "📋 ИНСТРУКЦИЯ:"
        echo "1. Скопируйте ключ выше (начинается с ssh-ed25519)"
        echo "2. Откройте: https://github.com/settings/ssh/new"
        echo "3. Вставьте ключ в поле 'Key'"
        echo "4. Нажмите 'Add SSH key'"
        echo ""
        read -p "Нажмите Enter после добавления ключа в GitHub..."
    fi
    
    echo ""
    echo "Настройка Git для использования SSH..."
    git remote set-url origin git@github.com:som1one/Novolunie-delta.git
    
    echo ""
    echo "Проверка подключения..."
    ssh -T git@github.com 2>&1 | head -1
    
    echo ""
    echo "✅ Настроено! Теперь можно пушить:"
    echo "   git push origin main"
    
else
    echo "❌ Неверный выбор!"
    exit 1
fi

echo ""
echo "✅ Готово!"
