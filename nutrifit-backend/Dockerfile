# syntax=docker/dockerfile:1.7
FROM maven:3.9.9-eclipse-temurin-21 AS build

WORKDIR /workspace
COPY pom.xml ./
RUN mvn -q -DskipTests dependency:go-offline
COPY src ./src
RUN mvn -q -DskipTests package

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app
COPY --from=build /workspace/target/nutrifit-backend-0.1.0.jar app.jar

RUN addgroup -S app && adduser -S app -G app
USER app

ENV PORT=8000
EXPOSE 8000

CMD ["sh", "-c", "java -jar /app/app.jar --server.port=${PORT}"]
