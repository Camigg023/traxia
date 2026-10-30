# ─── Etapa 1: Compilación ───
FROM maven:3.9.9-eclipse-temurin-21-alpine AS build
WORKDIR /app

# Copiar descriptor de dependencias
COPY backend/pom.xml .
RUN mvn dependency:go-offline -B || true

# Copiar código fuente y empaquetar
COPY backend/src ./src
RUN mvn clean package -DskipTests -B

# ─── Etapa 2: Imagen de Ejecución Ligera ───
FROM eclipse-temurin:21-jre-alpine
RUN apk add --no-cache ca-certificates
WORKDIR /app

# Copiar el artefacto generado
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-Xmx400m", "-Xms128m", "-jar", "app.jar"]
