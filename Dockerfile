# ─── Etapa 1: compilar el JAR ───────────────────────────────────────────────
FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /workspace

# Copiar solo los archivos de dependencias primero (caché de capas)
COPY backend/pom.xml .
COPY backend/mvnw .
COPY backend/.mvn .mvn

# Descargar dependencias (se cachea si pom.xml no cambia)
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B --no-transfer-progress

# Copiar el código fuente y compilar
COPY backend/src src
RUN ./mvnw package -DskipTests -B --no-transfer-progress

# ─── Etapa 2: imagen de producción (solo JRE, más liviana) ──────────────────
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Copiar el JAR generado
COPY --from=build /workspace/target/*.jar app.jar

# Render inyecta la variable PORT automáticamente
EXPOSE 8080

# Arrancar con memoria limitada (Render free tier tiene 512 MB RAM)
ENTRYPOINT ["java", "-Xmx400m", "-Xms128m", "-jar", "app.jar"]
