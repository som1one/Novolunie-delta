# PowerShell скрипт для настройки Git репозитория

Write-Host "🔧 Настройка Git репозитория для Novolunie..." -ForegroundColor Cyan

# Проверяем, инициализирован ли Git
if (-not (Test-Path ".git")) {
    Write-Host "📦 Инициализация Git репозитория..." -ForegroundColor Yellow
    git init
    git branch -M main
    Write-Host "✅ Git инициализирован" -ForegroundColor Green
} else {
    Write-Host "✅ Git уже инициализирован" -ForegroundColor Green
}

# Проверяем, есть ли remote
try {
    $remote = git remote get-url origin 2>$null
    if ($remote) {
        Write-Host "📡 Удаленный репозиторий уже настроен: $remote" -ForegroundColor Yellow
        $answer = Read-Host "Заменить на https://github.com/som1one/Novolunie-delta.git? (y/n)"
        if ($answer -eq "y" -or $answer -eq "Y") {
            git remote set-url origin https://github.com/som1one/Novolunie-delta.git
            Write-Host "✅ Remote обновлен" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "📡 Добавление удаленного репозитория..." -ForegroundColor Yellow
    git remote add origin https://github.com/som1one/Novolunie-delta.git
    Write-Host "✅ Remote добавлен" -ForegroundColor Green
}

# Добавляем все файлы
Write-Host "📝 Добавление файлов..." -ForegroundColor Yellow
git add .

# Проверяем статус
Write-Host ""
Write-Host "📊 Текущий статус:" -ForegroundColor Cyan
git status --short

Write-Host ""
Write-Host "✅ Готово!" -ForegroundColor Green
Write-Host ""
Write-Host "Следующие шаги:" -ForegroundColor Cyan
Write-Host "1. Проверьте изменения: git status"
Write-Host "2. Создайте коммит: git commit -m 'Initial commit: Novolunie website'"
Write-Host "3. Загрузите в репозиторий: git push -u origin main"
