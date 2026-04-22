# 📋 Шпаргалка: Docker Compose

## Что такое Docker Compose?

**Docker Compose** — инструмент для описания и запуска многоконтейнерных Docker-приложений с помощью одного YAML-файла (`docker-compose.yml`).

Вместо того чтобы запускать каждый контейнер вручную через `docker run ...`, вы описываете всю инфраструктуру в одном файле и управляете ею одной командой.

---

## Структура docker-compose.yml

```yaml
services:           # список сервисов (контейнеров)
  service_name:
    image: ...      # готовый образ из Docker Hub
    build: ./path   # путь до Dockerfile для сборки образа
    ports:
      - "host:container"
    environment:
      KEY: VALUE
    env_file:
      - .env
    volumes:
      - host_path:/container_path
      - named_volume:/container_path
    networks:
      - network_name
    depends_on:
      - other_service
    restart: unless-stopped

networks:            # определение сетей
  network_name:
    driver: bridge

volumes:             # именованные тома
  named_volume:
```

---

## Ключевые директивы

### `build`
Указывает путь до папки с `Dockerfile` или объект с параметрами:
```yaml
build:
  context: ./backend    # рабочая директория для сборки
  dockerfile: Dockerfile
```

### `image`
Используется готовый образ из реестра (Docker Hub и др.):
```yaml
image: postgres:15
image: nginx:alpine
```

### `ports`
Проброс портов: `"порт_хоста:порт_контейнера"`
```yaml
ports:
  - "80:80"
  - "8080:8080"
```

### `volumes`
Монтирование файлов/директорий:
```yaml
volumes:
  - ./local/path:/container/path   # bind mount
  - db_data:/var/lib/postgresql/data  # именованный том
```

### `networks`
Контейнеры в одной сети видят друг друга по имени сервиса:
```yaml
networks:
  - frontend
  - backend
```
> Сервис `api` будет доступен по адресу `http://api:8080` внутри сети

### `environment` / `env_file`
Переменные окружения:
```yaml
environment:
  POSTGRES_USER: postgres
  POSTGRES_DB: mydb

env_file:
  - ./backend/.env   # загружает переменные из файла
```

### `depends_on`
Порядок запуска (но не ожидание готовности!):
```yaml
depends_on:
  - db
```

### `restart`
Политика перезапуска контейнера:

| Значение | Описание |
|---|---|
| `no` | Никогда не перезапускать (по умолчанию) |
| `always` | Всегда перезапускать |
| `unless-stopped` | Перезапускать, пока вручную не остановить |
| `on-failure` | Только при ненулевом коде выхода |

---

## Сети в Docker Compose

Docker Compose создаёт изолированные сети. Контейнеры общаются **по имени сервиса**:

```
[nginx] ---(frontend сеть)--- [api]
                               [api] ---(backend сеть)--- [db]
```

- `nginx` видит `api`, но не видит `db` (разные сети)
- `api` видит и `nginx`, и `db` (состоит в обеих сетях)
- `db` видит только `api`

Это обеспечивает **изоляцию** и **безопасность**.

---

## Тома (Volumes)

| Тип | Синтаксис | Назначение |
|---|---|---|
| Bind Mount | `./local:/container` | Привязка к папке хоста |
| Named Volume | `vol_name:/container` | Управляемый Docker том |
| Anonymous | `/container/path` | Временный, удаляется с контейнером |

**Named volumes** переживают перезапуск и удаление контейнера — данные сохраняются.

---

## Основные команды

```bash
# Запустить все сервисы в фоне
docker compose up -d

# Пересобрать образы и запустить
docker compose up -d --build

# Остановить все сервисы
docker compose down

# Остановить и удалить тома
docker compose down -v

# Посмотреть статус контейнеров
docker compose ps

# Посмотреть логи
docker compose logs
docker compose logs api          # логи конкретного сервиса
docker compose logs -f api       # в реальном времени

# Выполнить команду внутри контейнера
docker compose exec api bash

# Перезапустить сервис
docker compose restart api
```

---

## Типичная архитектура веб-приложения

```
Клиент (браузер)
     │
     ▼ :80
  [nginx]          ← раздаёт статику (HTML/CSS/JS)
     │               проксирует /api/* запросы
     ▼ :8080
  [backend/api]    ← бизнес-логика, REST API
     │
     ▼ :5432
  [database]       ← хранилище данных (PostgreSQL)
```

---

## Переменные окружения в .env файле

```dotenv
# backend/.env
SERVER_ADDR=0.0.0.0
SERVER_PORT=8080
DB_ADDR=db          # имя сервиса БД в compose
DB_USER=postgres
DB_PASSWORD=secret
DB_PORT=5432
DB_NAME=myapp
```

> ⚠️ Никогда не коммитьте `.env` в git! Добавьте его в `.gitignore`.

---

## Частые ошибки

| Ошибка | Причина | Решение |
|---|---|---|
| `Connection refused` к БД | API стартовал раньше БД | Добавить `depends_on`, healthcheck или retry в коде |
| `Port already in use` | Порт занят другим процессом | Изменить порт хоста в `ports` |
| Изменения в коде не применились | Образ не пересобран | Запустить с флагом `--build` |
| Контейнер постоянно перезапускается | Ошибка в приложении | Проверить `docker compose logs service_name` |
