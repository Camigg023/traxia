# ─── Etapa 1: Compilación ───
FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /app

# Copiar descriptores para aprovechar caché de dependencias
COPY pom.xml .
RUN mvn dependency:go-offline -B || true

# Copiar código fuente y empaquetar sin ejecutar tests en la imagen
COPY src ./src
RUN mvn clean package -DskipTests -B

# ─── Etapa 2: Imagen de Ejecución Ligera ───
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

# Crear usuario sin privilegios por seguridad
RUN addgroup --system traxia && adduser --system --ingroup traxia traxia
USER traxia:traxia

# Copiar el artefacto generado
COPY --from=build /app/target/traxia-backend-*.jar app.jar

ENV APP_ENV=production \
    APP_PORT=8080 \
    JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC"

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
