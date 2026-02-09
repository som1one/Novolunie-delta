# 🚀 Быстрые команды для сервера

## Обновление сайта из Git

```bash
# Подключитесь к серверу
ssh user@85.239.44.197

# Выполните эти команды:
cd ~/novolunie
git pull origin main
docker compose down
docker compose up -d --build
docker compose ps
```

## Или используйте скрипт:

```bash
cd ~/novolunie
chmod +x UPDATE_SERVER.sh
./UPDATE_SERVER.sh
```

## Проверка работы

```bash
# Проверьте сайт
curl -I http://85.239.44.197

# Проверьте логи
docker compose logs -f
```

---

**IP сервера:** 85.239.44.197  
**Репозиторий:** https://github.com/som1one/Novolunie-delta.git
