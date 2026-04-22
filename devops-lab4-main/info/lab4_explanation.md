# Лабораторная работа №4 — Шпаргалка: Docker Compose

---

## Архитектура проекта

```
Браузер
  │
  ▼
[nginx :80]  ──── раздаёт фронт (dist/)
  │                proxy_pass /api/v1 → api:8080
  ▼
[api :8080]  ──── FastAPI (Python)
  │
  ▼
[db :5432]   ──── PostgreSQL 15
```

### Сети

| Сервис | frontend | backend |
|--------|:--------:|:-------:|
| nginx  | ✓        |         |
| api    | ✓        | ✓       |
| db     |          | ✓       |

> `db` недоступна снаружи — только через `api`. Это сетевая изоляция.

---

## docker-compose.yml — разбор по частям

```yaml
services:

  api:
    build:
      context: ./backend       # откуда брать файлы для сборки
      dockerfile: Dockerfile   # какой Dockerfile использовать
    networks:
      - frontend               # видит nginx
      - backend                # видит db
    ports:
      - "8080:8080"            # host:container
    env_file:
      - ./backend/.env         # переменные окружения из файла
    depends_on:
      - db                     # стартует после db (не ждёт готовности!)
    restart: unless-stopped    # перезапуск при падении, кроме ручной остановки

  db:
    image: postgres:15         # готовый образ с Docker Hub
    networks:
      - backend
    volumes:
      - db_data:/var/lib/postgresql/data   # именованный том = данные не теряются
    environment:               # переменные прямо в compose
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: devopsLabs
    restart: unless-stopped

  nginx:
    build:
      context: ./nginx
      dockerfile: Dockerfile
    networks:
      - frontend
    ports:
      - "80:80"
    volumes:
      - ./nginx/dist:/public   # bind mount: папка хоста → папка контейнера
    depends_on:
      - api
    restart: unless-stopped

networks:
  frontend:
    driver: bridge   # стандартная изолированная сеть
  backend:
    driver: bridge

volumes:
  db_data:           # именованный том — управляется Docker'ом
```

---

## Dockerfile backend (Python)

```dockerfile
FROM python:3.10              # базовый образ

COPY requirements.txt .       # копируем зависимости
RUN pip install -r requirements.txt && rm requirements.txt

WORKDIR /app                  # рабочая директория внутри контейнера
COPY src .                    # копируем исходники

CMD ["python", "main.py"]     # команда запуска
```

**Зачем сначала копируем requirements.txt, а потом src?**
Docker кеширует слои. Если код изменился, но зависимости — нет, `pip install` не перезапускается. Экономия времени сборки.

---

## Dockerfile nginx (multi-stage)

```dockerfile
# Стадия 1: сборка nginx из исходников
FROM alpine:3 as nginxbuild
RUN apk add ... && wget nginx-source && ./configure ... && make && make install

# Стадия 2: финальный образ — только бинарник, без инструментов сборки
FROM alpine:3
COPY --from=nginxbuild /nginx /nginx   # копируем только готовый nginx
COPY nginx.conf /nginx/conf/nginx.conf
```

**Multi-stage build** — финальный образ маленький, компилятор и wget в него не попадают.

---

## nginx.conf — как работает проксирование

```nginx
server {
    listen 80;
    root /public;          # фронт лежит здесь

    location / {
        index index.html;
        try_files $uri /index.html =404;   # SPA: все маршруты → index.html
    }

    location /api/v1 {
        proxy_pass http://api:8080;        # имя сервиса = DNS внутри Docker-сети
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

> `api` в `proxy_pass` — это имя сервиса из `docker-compose.yml`. Docker автоматически резолвит его в IP контейнера.

---

## .env файл backend

```env
SERVER_ADDR="0.0.0.0"    # слушать на всех интерфейсах
SERVER_PORT=8080
DB_ADDR=db               # имя сервиса db — работает как hostname
DB_USER=postgres
DB_PASSWORD=postgres
DB_PORT=5432
DB_NAME=devopsLabs
```

> Значения `DB_USER`, `DB_PASSWORD`, `DB_NAME` должны совпадать с `POSTGRES_*` в `docker-compose.yml`.

---

## Приложение (FastAPI)

**Стек:** Python + FastAPI + SQLAlchemy + PostgreSQL

### API endpoints (`/api/v1/users`)

| Метод  | Путь           | Действие                  |
|--------|----------------|---------------------------|
| GET    | `/`            | Список всех пользователей |
| GET    | `/{id}`        | Получить пользователя     |
| POST   | `/`            | Создать пользователя      |
| PUT    | `/{id}`        | Обновить пользователя     |
| DELETE | `/?user_id=id` | Удалить пользователя      |

### Модель пользователя

```python
User:
  id       int  (автоинкремент)
  name     str
  age      int
  male     bool
```

---

## Ключевые концепции Docker Compose

### volumes — типы

| Тип | Пример | Где хранится |
|-----|--------|-------------|
| Именованный том | `db_data:/var/lib/postgresql/data` | Управляет Docker |
| Bind mount | `./nginx/dist:/public` | Папка на хосте |

### depends_on

```yaml
depends_on:
  - db
```

Гарантирует **порядок запуска**, но НЕ гарантирует что db готова принимать подключения. Для этого нужен `healthcheck`.

### restart политики

| Значение | Поведение |
|----------|-----------|
| `no` | Не перезапускать (по умолчанию) |
| `always` | Всегда перезапускать |
| `unless-stopped` | Перезапускать, кроме ручной остановки |
| `on-failure` | Только при ненулевом exit code |

---

## Основные команды

```bash
# Собрать и запустить все сервисы
docker compose up --build

# Запустить в фоне
docker compose up -d --build

# Посмотреть логи
docker compose logs -f
docker compose logs -f api       # только api

# Статус сервисов
docker compose ps

# Остановить и удалить контейнеры
docker compose down

# Удалить вместе с томами (данные БД тоже удалятся!)
docker compose down -v

# Войти в контейнер
docker compose exec api sh
docker compose exec db psql -U postgres -d devopsLabs

# Перезапустить один сервис
docker compose restart api
```

---

## Как проверить что всё работает

```bash
# 1. Убедиться что все сервисы Up
docker compose ps

# 2. Открыть в браузере
http://localhost              # фронт
http://localhost/api/v1/users # список пользователей (должен вернуть [])

# 3. Создать пользователя
curl -X POST http://localhost/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Ivan","age":20,"male":true}'

# 4. Проверить — db не доступна с хоста напрямую (порт 5432 не проброшен)
```

---

## Схема взаимодействия (итог)

```
Хост
├── :80   → nginx  (frontend сеть)
│           ├── /         → раздаёт /public (dist/)
│           └── /api/v1   → proxy_pass → api:8080
│
├── :8080 → api   (frontend + backend сети)
│           └── → db:5432
│
└── :5432   НЕ ДОСТУПЕН  (db только в backend сети, порт не проброшен)
```
