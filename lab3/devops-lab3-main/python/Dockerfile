# Используем официальный образ Python
FROM python:3.12-slim

# Указываем рабочую директорию
WORKDIR /app

# Копируем файл с зависимостями
COPY requirements.txt .

# Устанавливаем зависимости
RUN pip install --no-cache-dir -r requirements.txt

# Копируем исходный код приложения
COPY src/ ./src/

# Указываем переменную окружения для порта (по умолчанию 8080)
ENV SERVER_PORT=8080

# Открываем порт
EXPOSE 8080

# Запускаем приложение
CMD ["python", "src/main.py"]
