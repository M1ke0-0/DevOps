# Стадия сборки
FROM maven:3.8.5-openjdk-17-slim AS build

# Указываем рабочую директорию
WORKDIR /app

# Копируем файлы проекта
COPY pom.xml .
COPY src ./src

# Собираем JAR
RUN mvn clean package -DskipTests


# Стадия запуска
FROM eclipse-temurin:17.0.14_7-jre-jammy

# Указываем рабочую директорию
WORKDIR /app

# Копируем только готовый JAR из стадии сборки
COPY --from=build /app/target/*.jar app.jar

# Указываем точку входа
ENTRYPOINT ["java", "-jar", "app.jar"]
