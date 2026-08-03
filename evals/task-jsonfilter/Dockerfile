ARG BASE_IMAGE=xsh-factory-base:latest
FROM ${BASE_IMAGE}

# task-jsonfilter is the only current eval that needs jq beyond the shared base.
ARG JQ_VERSION=1.8.1-r0
RUN apk add --no-cache "jq=${JQ_VERSION}"

ARG FACTORY_BUILD_ID=unknown
LABEL org.xsh.factory.build-id="${FACTORY_BUILD_ID}"

