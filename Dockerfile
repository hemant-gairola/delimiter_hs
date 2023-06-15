# Copyright (c) 2021, 2022 by Delphix. All rights reserved.
FROM alpine:3.16.0 AS build

RUN apk --no-cache add openjdk11


ENV MINIMAL_JRE="/opt/min-jre"

RUN /usr/lib/jvm/java-11-openjdk/bin/jlink \
    --compress=2 \
    --no-header-files \
    --no-man-pages \
    --add-modules \
        java.base,java.desktop,java.instrument,java.logging,java.management,java.naming,java.security.jgss,java.sql,java.sql.rowset,java.xml,jdk.crypto.ec,jdk.jcmd,jdk.jdwp.agent,jdk.unsupported \
    --output "${MINIMAL_JRE}"

# Vault installation largely inspired by the official docker vault image
# https://github.com/hashicorp/docker-vault/blob/fb6bc85ef0828edb45abac40d5cb55a1d5bf50a6/0.X/Dockerfile
# This is the release of Vault to pull in.
ARG VAULT_VERSION=1.6.3

# Set up certificates, Vault base tools, and Vault.
RUN set -eux; \
    apk add --no-cache ca-certificates gnupg openssl libcap su-exec dumb-init tzdata && \
    ARCH="amd64"; \
    VAULT_GPGKEY=C874011F0AB405110D02105534365D9472D7468F; \
    found=''; \
    for server in \
        hkp://p80.pool.sks-keyservers.net:80 \
        hkp://keyserver.ubuntu.com:80 \
        hkp://keys.openpgp.org:80 \
        hkp://pgp.mit.edu:80 \
    ; do \
        echo "Fetching GPG key $VAULT_GPGKEY from $server"; \
        gpg --batch --keyserver "$server" --recv-keys "$VAULT_GPGKEY" && found=yes && break; \
    done; \
    test -z "$found" && echo >&2 "error: failed to fetch GPG key $VAULT_GPGKEY" && exit 1; \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${ARCH}.zip && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS && \
    wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS.sig && \
    gpg --batch --verify vault_${VAULT_VERSION}_SHA256SUMS.sig vault_${VAULT_VERSION}_SHA256SUMS && \
    grep vault_${VAULT_VERSION}_linux_${ARCH}.zip vault_${VAULT_VERSION}_SHA256SUMS | sha256sum -c && \
    unzip -d /tmp/build vault_${VAULT_VERSION}_linux_${ARCH}.zip

FROM alpine:3.16.0

RUN apk --no-cache add sqlite bash jq
RUN apk add --update python3
RUN apk add --update py-pip
# Create a user with no password, home directory, or shell
# Create our user and group first to make sure their IDs get assigned consistently
RUN addgroup --gid 50 delphix && adduser --no-create-home --disabled-password --ingroup delphix --shell "/sbin/nologin" --uid 65436 delphix

ENV JAVA_HOME="/opt/min-jre"
ENV PATH="${JAVA_HOME}/bin:$PATH"
#ENV JAVA_TOOL_OPTIONS -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:9092

COPY --from=build "${JAVA_HOME}" "${JAVA_HOME}"
COPY --from=build /tmp/build/vault /bin/vault


WORKDIR /opt/delphix
COPY requirements.txt .
RUN pip install -r /opt/delphix/requirements.txt
ARG VERSION
COPY src /opt/delphix/src

RUN mkdir -p /data /etc/config && chown -R delphix:delphix /data /opt/delphix /etc/config
# Will create an anonymous volume if one isn't mounted at runtime
VOLUME ["/data"]

USER delphix

ENTRYPOINT ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "80"]