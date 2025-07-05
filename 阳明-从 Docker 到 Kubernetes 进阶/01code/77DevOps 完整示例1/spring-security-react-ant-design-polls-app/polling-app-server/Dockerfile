FROM openjdk:8-jdk-alpine

MAINTAINER aaron <kkk_en@163.com>

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV TZ=Asia/Shanghai

RUN mkdir /app

WORKDIR /app

COPY target/polls-0.0.1-SNAPSHOT.jar /app/polls.jar

EXPOSE 8080

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar","/app/polls.jar"]