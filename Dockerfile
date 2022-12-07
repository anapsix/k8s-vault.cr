# syntax=docker/dockerfile:1.4

## this stage installs everything required to build the project
FROM alpine:3.17 as build
ARG TARGETPLATFORM
ARG TARGETARCH
ARG UPX_PACK=1
RUN \
  echo >&2 "## TARGETPLATFORM: ${TARGETPLATFORM}" && \
  echo >&2 "## TARGETARCH: ${TARGETARCH}" && \
  echo >&2 "## arch: $(arch)" && \
  echo >&2 "## UPX_PACK: ${UPX_PACK}" && \
  PACKAGES="musl-dev yaml-static crystal shards" && \
  if [ "${UPX_PACK}" == "1" ]; then \
    PACKAGES="${PACKAGES} upx"; \
  fi && \
  echo >&2 "### installing OS packages: ${PACKAGES}" && \
  apk add --no-cache $PACKAGES
WORKDIR /tmp
COPY --link VERSION .
COPY --link shard.yml .
COPY --link k8s-vault_example.yaml .
COPY --link k8s-vault-completion.bash .
COPY --link ./src ./src
RUN \
    echo >&2 "### installing dependencies.." && \
    shards install && \
    echo >&2 "### building.." && \
    crystal build --progress --release --static src/cli.cr -o /tmp/k8s-vault && \
    if [ "${UPX_PACK}" == "1" ]; then \
      echo >&2 "### upx packing.." && \
      upx /tmp/k8s-vault; \
    fi && \
    echo >&2 "## Version check: $(/tmp/k8s-vault -v)" && \
    echo >&2 "## Help Check" && \
    /tmp/k8s-vault --help


## this stage creates final docker image
FROM busybox as release
COPY --from=build /tmp/k8s-vault /bin/k8s-vault
USER nobody
ENTRYPOINT ["/bin/k8s-vault"]
CMD ["--help"]
