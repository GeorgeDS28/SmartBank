# Build stage: compiles the jar inside the container so the image does not
# depend on whatever happens to be in target/ on the host.
FROM maven:3-eclipse-temurin-21 AS build
WORKDIR /build

COPY pom.xml ./
COPY src ./src

# The cache mount keeps downloaded dependencies across rebuilds, which matters
# because this repo lives under OneDrive and re-copying the context is slow.
# Testing happens in CI, not here, so the image build skips it.
# The jar is renamed to a fixed path because Spring Boot also emits
# <artifact>.jar.original; a versioned filename here would break the build the
# moment pom.xml stops saying 0.0.1-SNAPSHOT.
RUN --mount=type=cache,target=/root/.m2 mvn -B -DskipTests package \
    && cp target/smartbank-backend-*.jar /build/app.jar

# Runtime stage: JRE only, no compiler and no test fixtures.
FROM eclipse-temurin:21-jre AS runtime
WORKDIR /app

COPY --from=build /build/app.jar app.jar

# Dedicated unprivileged account. The base image's own uid 1000 user belongs to
# the sudo and adm groups, which is fine interactively and wrong for a service
# reachable from the internet.
RUN groupadd --system --gid 1001 appgroup \
    && useradd --system --uid 1001 --gid appgroup --no-create-home appuser

USER 1001:1001

# Containers are sized by their memory limit, so the heap follows it instead of
# defaulting to a quarter of whatever host RAM the scheduler sees.
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75"

EXPOSE 8080

# Shell form, because the port has to come from PORT at probe time: a fixed
# 8080 here would report every Render container unhealthy once the platform
# injects 10000. start-period covers the measured 20-26 second Spring Boot
# startup, so a slow boot is not mistaken for a dead one.
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
    CMD curl -fsS "http://127.0.0.1:${PORT:-8080}/actuator/health" || exit 1

# exec keeps the JVM as PID 1 so it receives shutdown signals instead of being
# orphaned behind the shell. JAVA_OPTS is expanded at runtime, so overriding it
# with -e JAVA_OPTS=... works without rebuilding.
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
