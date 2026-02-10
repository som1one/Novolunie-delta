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

## Открытие портов 80 и 443

### Автоматический способ:

```bash
cd ~/novolunie
git pull origin main
chmod +x open-ports.sh
./open-ports.sh
```

### Ручной способ (UFW):

```bash
# Откройте порты в файрволе
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Проверьте
sudo ufw status numbered
```

## Исправление: Сервер исключен из балансировки (порт 80)

```bash
cd ~/novolunie
git pull origin main
chmod +x fix-port-80.sh
./fix-port-80.sh
```

### Или вручную:

```bash
# 1. Откройте порты в файрволе
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 2. Остановите системный Nginx (если запущен)
sudo systemctl stop nginx
sudo systemctl disable nginx

# 3. Перезапустите контейнер
cd ~/novolunie
docker compose restart

# 4. Проверьте
curl -I http://localhost
docker compose ps
```

---

**IP сервера:** 85.239.44.197  
**Домен:** e-novolunie.ru  
**Репозиторий:** https://github.com/som1one/Novolunie-delta.git
