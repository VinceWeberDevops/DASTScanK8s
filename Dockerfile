# Build stage
FROM maven:3.9.9-sapmachine-24 as builder
WORKDIR /usr/src/easybuggy/
COPY pom.xml .
RUN mvn -B dependency:go-offline
COPY src ./src
RUN mvn -B package

# Runtime stage
FROM openjdk:25-slim
WORKDIR /app
COPY --from=builder /usr/src/easybuggy/target/easybuggy.jar .
RUN mkdir logs && \
    chmod 777 logs

ENV JAVA_OPTS="\
    -XX:MaxMetaspaceSize=128m \
    -Xmx256m \
    -XX:MaxDirectMemorySize=90m \
    -XX:+UseSerialGC"

ENV GC_OPTS="\
    -Xloggc:logs/gc_%p_%t.log \
    -XX:+PrintHeapAtGC \
    -XX:+PrintGCDetails \
    -XX:+PrintGCDateStamps \
    -XX:+UseGCLogFileRotation \
    -XX:NumberOfGCLogFiles=5 \
    -XX:GCLogFileSize=10M \
    -XX:GCTimeLimit=15 \
    -XX:GCHeapFreeLimit=50"

ENV DEBUG_OPTS="\
    -XX:+HeapDumpOnOutOfMemoryError \
    -XX:HeapDumpPath=logs/ \
    -XX:ErrorFile=logs/hs_err_pid%p.log \
    -agentlib:jdwp=transport=dt_socket,server=y,address=9009,suspend=n"

ENV DERBY_OPTS="\
    -Dderby.stream.error.file=logs/derby.log \
    -Dderby.infolog.append=true \
    -Dderby.language.logStatementText=true \
    -Dderby.locks.deadlockTrace=true \
    -Dderby.locks.monitor=true \
    -Dderby.storage.rowLocking=true"

ENV JMX_OPTS="\
    -Dcom.sun.management.jmxremote \
    -Dcom.sun.management.jmxremote.port=7900 \
    -Dcom.sun.management.jmxremote.ssl=false \
    -Dcom.sun.management.jmxremote.authenticate=false"

EXPOSE 8080 9009 7900

CMD java $JAVA_OPTS $GC_OPTS $DEBUG_OPTS $DERBY_OPTS $JMX_OPTS -ea -jar easybuggy.jar
