# Базовый образ с Maven и JDK 17
FROM maven:3.8.5-openjdk-17-slim

# Рабочая директория
WORKDIR /app

# Копируем проект
COPY pom.xml .
COPY src ./src

# Собираем приложение
RUN mvn clean package -DskipTests

# Копируем JAR-файл для удобного запуска (как указано в задании)
RUN cp target/*.jar app.jar

# Открываем порт (Spring Boot по умолчанию 8080)
EXPOSE 8080

# Точка входа
ENTRYPOINT ["java", "-jar", "app.jar"]
