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

FROM debian:buster

# install cron and the docker cli (used to send SIGHUP to target containers)
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian buster stable" && \
    apt-get update && \
    apt-get install -y cron docker-ce-cli

# install docker-gen
COPY --from=dockergen /usr/local/bin/docker-gen /usr/local/bin/docker-gen

# template crontab; get's populated with commands to send SIGHUP to containers
COPY ./crontab.tmbl /var/lib/docker_cron/crontab.tmpl

# cron -f & allows cron stdout to be directed at host docker
# <- redirect output to cron stdout and stderr
# this is also done for the notify command
ENTRYPOINT ["bash", "-c", "cron -f & docker-gen -notify 'crontab /etc/cron.d/crontab 1>/proc/$(cat /var/run/crond.pid)/fd/1 2>/proc/$(cat /var/run/crond.pid)/fd/2' -watch /var/lib/docker_cron/crontab.tmpl /etc/cron.d/crontab"]

