# Stage 1: Build
FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY . .
RUN mvn clean package -DskipTests

# Stage 2: Run
FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY --from=build /app/target/bankapp-0.0.1-SNAPSHOT.jar app.jar

# Expose application port 
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
