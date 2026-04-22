# Лабораторная работа №4: Разбор и объяснение

## Тема

**Описание многоконтейнерного приложения с помощью Docker Compose.**

Цель — научиться связывать несколько Docker-контейнеров в единое приложение: бэкенд, база данных и веб-сервер.

---

## Архитектура приложения

```
Браузер
  │  HTTP :80
  ▼
┌─────────────────────────────┐
│  nginx (сеть: frontend)     │  ← раздаёт статику, проксирует /api/v1
└────────────┬────────────────┘
             │ proxy_pass → api:8080
             ▼
┌─────────────────────────────┐
│  api — FastAPI              │  ← сети: frontend + backend
│  (Python, uvicorn, :8080)   │
└────────────┬────────────────┘
             │ подключение к db:5432
             ▼
┌─────────────────────────────┐
│  db — PostgreSQL            │  ← сеть: backend
│  данные в томе db_data      │
└─────────────────────────────┘
```

Две сети (`frontend`, `backend`) обеспечивают изоляцию:
- nginx и api видят друг друга (оба в `frontend`)
- api и db видят друг друга (оба в `backend`)
- nginx **не имеет** прямого доступа к db — это намеренная защита

---

## Разбор docker-compose.yml по сервисам

### Сервис `api`

```yaml
api:
  build:
    context: ./backend
    dockerfile: Dockerfile
  networks:
    - frontend
    - backend
  ports:
    - "8080:8080"
  env_file:
    - ./backend/.env
  depends_on:
    - db
  restart: unless-stopped
```

| Что | Зачем |
|---|---|
| `build: context: ./backend` | Собирает образ из `backend/Dockerfile` |
| `networks: frontend + backend` | Стоит "между" nginx и db — связывает обе сети |
| `ports: 8080:8080` | Открывает порт для отладки с хоста |
| `env_file: ./backend/.env` | Передаёт настройки подключения к БД |
| `depends_on: db` | Гарантирует, что db запустится первой |
| `restart: unless-stopped` | Перезапускает при сбоях, но не при ручной остановке |

---

### Сервис `db`

```yaml
db:
  image: postgres:15
  networks:
    - backend
  volumes:
    - db_data:/var/lib/postgresql/data
  environment:
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: postgres
    POSTGRES_DB: devopsLabs
  restart: unless-stopped
```

| Что | Зачем |
|---|---|
| `image: postgres:15` | Готовый официальный образ PostgreSQL |
| `networks: backend` | Изолирован от nginx, виден только api |
| `volumes: db_data:/var/lib/postgresql/data` | Данные сохраняются между перезапусками |
| `POSTGRES_USER/PASSWORD/DB` | Учётные данные БД — должны совпадать с `.env` бэкенда |

> Значения `DB_USER`, `DB_PASSWORD`, `DB_NAME` в `backend/.env` должны совпадать
> с `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` здесь.

---

### Сервис `nginx`

```yaml
nginx:
  build:
    context: ./nginx
    dockerfile: Dockerfile
  networks:
    - frontend
  ports:
    - "80:80"
  volumes:
    - ./nginx/dist:/public
  depends_on:
    - api
  restart: unless-stopped
```

| Что | Зачем |
|---|---|
| `build: context: ./nginx` | Собирает образ из `nginx/Dockerfile` |
| `networks: frontend` | Видит только api, не видит db |
| `ports: 80:80` | Основная точка входа для браузера |
| `volumes: ./nginx/dist:/public` | Монтирует билд фронтенда внутрь контейнера |
| `depends_on: api` | Запускается после api |

---

## Как nginx связан с api

В `nginx/nginx.conf` настроен reverse proxy:

```nginx
location /api/v1 {
    proxy_pass http://api:8080;
}
```

- `api` — это имя сервиса в Docker Compose, Docker сам резолвит его в IP контейнера
- Запросы на `http://localhost/api/v1/...` nginx перенаправляет на `http://api:8080/api/v1/...`
- Статика (HTML, JS, CSS) из `/public` отдаётся напрямую

---

## Как бэкенд подключается к БД

В `backend/.env` задаются переменные:
```env
DB_ADDR=db        # имя сервиса db — Docker резолвит сам
DB_USER=postgres
DB_PASSWORD=postgres
DB_PORT=5432
DB_NAME=devopsLabs
```

Бэкенд (FastAPI + pydantic-settings) читает их через класс `Settings` и использует для подключения к PostgreSQL.

---

## Порядок запуска

```
db  →  api  →  nginx
```

`depends_on` задаёт порядок старта, но не ждёт готовности приложения внутри контейнера.
Если api падает с ошибкой подключения к db при первом старте — это нормально, `restart: unless-stopped` поднимет его снова.

---

## Что нужно сделать для выполнения лабы

1. Скопировать `backend/.env.example` в `backend/.env` и заполнить переменные:
   ```bash
   cp backend/.env.example backend/.env
   ```
   Убедиться, что `DB_ADDR=db`, и значения `DB_USER`, `DB_PASSWORD`, `DB_NAME`
   совпадают с переменными сервиса `db` в `docker-compose.yml`.

2. Положить билд фронтенда в `nginx/dist/` (или убедиться, что он уже там есть).

3. Запустить:
   ```bash
   docker compose up --build -d
   ```

4. Проверить статус:
   ```bash
   docker compose ps
   ```
   Все три сервиса должны быть в состоянии `running`, без постоянных рестартов.

5. Проверить в браузере: `http://localhost` — должна открыться страница фронтенда.

---

## Команды для отладки

```bash
# Посмотреть логи сервиса
docker compose logs -f api

# Зайти внутрь контейнера
docker compose exec api bash
docker compose exec db psql -U postgres -d devopsLabs

# Перезапустить один сервис
docker compose restart api

# Полностью пересобрать
docker compose down && docker compose up --build -d
```
