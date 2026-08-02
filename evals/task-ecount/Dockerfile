ARG BASE_IMAGE=xsh-factory-base:latest
FROM ${BASE_IMAGE}

# Ecount is the only current eval that needs fd beyond the shared base.
ARG FD_VERSION=10.2.0-r3
RUN apk add --no-cache "fd=${FD_VERSION}"
