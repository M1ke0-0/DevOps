FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/

ENV SERVER_PORT=8080

EXPOSE 8080

CMD ["python", "src/main.py"]
