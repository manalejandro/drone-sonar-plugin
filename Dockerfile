FROM golang:1.15-alpine as build
RUN mkdir -p /go/src/github.com/aosapps/drone-sonar-plugin
WORKDIR /go/src/github.com/aosapps/drone-sonar-plugin 
COPY *.go ./
COPY vendor ./vendor/
RUN GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o drone-sonar

FROM openjdk:17-slim-bullseye

ARG SONAR_VERSION=5.0.1.3006
ARG SONAR_SCANNER_CLI=sonar-scanner-cli-${SONAR_VERSION}
ARG SONAR_SCANNER=sonar-scanner-${SONAR_VERSION}
ARG NODEJS_VERSION=20

RUN apt-get update \
    && apt-get install -y curl gpg unzip \
    && apt-get clean

RUN echo "deb https://deb.nodesource.com/node_${NODEJS_VERSION}.x bookworm main" | tee /etc/apt/sources.list.d/nodesource.list
RUN curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/nodesource.gpg >/dev/null

RUN apt-get update \
    && apt-get install -y nodejs \
    && apt-get clean

COPY --from=build /go/src/github.com/aosapps/drone-sonar-plugin/drone-sonar /bin/
WORKDIR /bin

RUN curl https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/${SONAR_SCANNER_CLI}.zip -so /bin/${SONAR_SCANNER_CLI}.zip
RUN unzip ${SONAR_SCANNER_CLI}.zip \
    && rm ${SONAR_SCANNER_CLI}.zip 

ENV PATH $PATH:/bin/${SONAR_SCANNER}/bin

ENTRYPOINT /bin/drone-sonar
