ARG DOCKER_GEN_VERSION=0.9.0

# build docker-gen
# from https://github.com/nginx-proxy/nginx-proxy/blob/main/Dockerfile
FROM golang as dockergen
ARG DOCKER_GEN_VERSION
RUN git clone https://github.com/nginx-proxy/docker-gen \
    && cd /go/docker-gen \
    && git -c advice.detachedHead=false checkout $DOCKER_GEN_VERSION \
    && go mod download \
    && CGO_ENABLED=0 GOOS=linux go build -ldflags "-X main.buildVersion=${DOCKER_GEN_VERSION}" ./cmd/docker-gen \
    && go clean -cache \
    && mv docker-gen /usr/local/bin/ \
    && cd - \
    && rm -rf /go/docker-gen

FROM debian

RUN apt-get update && \
    apt-get install -y cron

# install docker-gen
COPY --from=dockergen /usr/local/bin/docker-gen /usr/local/bin/docker-gen

# template crontab; get's populated with commands to send SIGHUP to containers
COPY ./crontab.tmpl ./init.sh /var/lib/docker_cron/

ENTRYPOINT ["sh", "/var/lib/docker_cron/init.sh"]

