FROM maven:3.9.11-eclipse-temurin-21 AS build

WORKDIR /app
COPY DunyaUlkeleri/pom.xml .
COPY DunyaUlkeleri/src ./src
RUN mvn -q -DskipTests package

FROM eclipse-temurin:21-jre

WORKDIR /app
COPY --from=build /app/target/DunyaUlkeleri-0.0.1-SNAPSHOT.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
