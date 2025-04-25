# Stage 1: Build the application
FROM maven:3.8-jdk-8 AS builder
WORKDIR /usr/src/app
COPY . .
RUN mvn -B package

# Stage 2: Runtime environment
FROM openjdk:25-slim
WORKDIR /app

COPY --from=builder /usr/src/app/target/easybuggy.jar .

RUN mkdir -p /app/logs

ENV JAVA_OPTS="-Xmx256m -XX:MaxMetaspaceSize=129m -XX:MaxDirectMemorySize=90m -XX:+UseSerialGC -Xloggc:/app/logs/gc_%p_%t.log -XX:+PrintGCDetails -agentlib:jdwp=transport=dt_socket,server=y,address=9009,suspend=n -Dcom.sun.management.jmxremote.port=7900 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"

EXPOSE 8080 9009 7900

CMD ["sh", "-c", "java ${JAVA_OPTS} -jar easybuggy.jar"]