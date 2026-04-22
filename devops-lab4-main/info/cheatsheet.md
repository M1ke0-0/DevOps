# Шпаргалка: Docker Compose

## Что такое Docker Compose

Docker Compose — инструмент для описания и запуска многоконтейнерных Docker-приложений.
Вся конфигурация пишется в файл `docker-compose.yml`, после чего одной командой поднимается вся инфраструктура.

---

## Структура файла docker-compose.yml

```yaml
version: "3.9"          # версия формата (можно опустить в новых версиях)

services:               # описание контейнеров
  имя_сервиса:
    image: ...          # готовый образ с Docker Hub
    build:              # или сборка из Dockerfile
      context: ./путь
      dockerfile: Dockerfile
    ports:
      - "хост:контейнер"
    environment:
      KEY: value
    env_file:
      - .env
    volumes:
      - хост_путь:путь_в_контейнере
      - имя_тома:путь_в_контейнере
    networks:
      - имя_сети
    depends_on:
      - другой_сервис
    restart: unless-stopped

networks:               # пользовательские сети
  имя_сети:
    driver: bridge

volumes:                # именованные тома
  имя_тома:
```

---

## Ключевые директивы

| Директива | Описание |
|---|---|
| `image` | Использовать готовый образ |
| `build` | Собрать образ из Dockerfile |
| `ports` | Проброс портов `хост:контейнер` |
| `environment` | Переменные окружения прямо в файле |
| `env_file` | Переменные окружения из файла `.env` |
| `volumes` | Монтирование директорий или именованных томов |
| `networks` | Подключение к сетям |
| `depends_on` | Порядок запуска (ждёт старта зависимости) |
| `restart` | Политика перезапуска: `no`, `always`, `unless-stopped`, `on-failure` |

---

## Сети (networks)

Сети изолируют трафик между группами сервисов.

- Сервисы в одной сети видят друг друга **по имени сервиса** (DNS внутри Docker).
- Сервисы в разных сетях **не видят** друг друга напрямую.

```
nginx  ──[frontend]──  api  ──[backend]──  db
```

Nginx видит api, api видит db, но nginx не видит db напрямую — это правильная изоляция.

---

## Тома (volumes)

| Тип | Пример | Назначение |
|---|---|---|
| Bind mount | `./local:/app` | Монтирует папку с хоста |
| Named volume | `db_data:/var/lib/postgresql/data` | Данные живут в Docker, не теряются при пересборке |

---

## Основные команды

```bash
# Поднять все сервисы (собрать образы если нужно)
docker compose up --build

# Поднять в фоне
docker compose up -d --build

# Остановить и удалить контейнеры
docker compose down

# Остановить и удалить контейнеры + тома
docker compose down -v

# Посмотреть статус
docker compose ps

# Логи всех сервисов
docker compose logs -f

# Логи конкретного сервиса
docker compose logs -f api

# Выполнить команду внутри контейнера
docker compose exec api bash

# Пересобрать конкретный сервис
docker compose build api
```

---

## Переменные окружения

Файл `.env` (рядом с `docker-compose.yml` или указанный через `env_file`):
```env
DB_ADDR=db
DB_USER=postgres
DB_PASSWORD=secret
DB_PORT=5432
DB_NAME=mydb
```

> Значение `DB_ADDR=db` — это имя сервиса `db` в Docker Compose. Внутри сети Docker он резолвится автоматически.

---

## Dockerfile — напоминание

```dockerfile
FROM python:3.11-slim          # базовый образ

WORKDIR /app                   # рабочая директория

COPY requirements.txt .
RUN pip install -r requirements.txt   # установка зависимостей

COPY . .                       # копирование кода

CMD ["python", "main.py"]      # команда запуска
```

---

## Типичная архитектура веб-приложения

```
Браузер
  │  :80
  ▼
[nginx] ──── раздаёт статику (HTML/JS/CSS) из /public
  │  proxy_pass /api/v1 → api:8080
  ▼
[api (FastAPI)] ──── обрабатывает запросы
  │  подключается к db:5432
  ▼
[db (PostgreSQL)] ──── хранит данные в именованном томе
```

---

## Частые ошибки

| Ошибка | Причина | Решение |
|---|---|---|
| `connection refused` к БД | api стартовал раньше db | Добавить `depends_on: db` или healthcheck |
| Переменная не читается | Не указан `env_file` или опечатка | Проверить имя файла и ключи |
| Порт уже занят | На хосте уже слушает этот порт | Изменить левый порт в `ports` |
| Контейнер постоянно рестартует | Ошибка в приложении | `docker compose logs имя_сервиса` |
