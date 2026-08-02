ARG BASE_IMAGE=xsh-factory-base:latest
FROM ${BASE_IMAGE}

ARG FACTORY_BUILD_ID=unknown
LABEL org.xsh.factory.build-id="${FACTORY_BUILD_ID}"

# Ecount is the only current eval that needs fd beyond the shared base.
ARG FD_VERSION=10.2.0-r3
RUN apk add --no-cache "fd=${FD_VERSION}"
