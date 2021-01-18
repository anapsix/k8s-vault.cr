## this stage installs everything required to build the project
FROM alpine:3.13 as build
RUN apk add --no-cache musl-dev yaml-static crystal shards upx
WORKDIR /tmp
COPY VERSION .
COPY shard.yml .
COPY k8s-vault_example.yaml .
COPY k8s-vault-completion.bash .
COPY ./src ./src
RUN \
    shards install && \
    crystal build --progress --release --static src/cli.cr -o /tmp/k8s-vault && \
    upx /tmp/k8s-vault && \
    echo >&2 "## Version check: $(/tmp/k8s-vault -v)" && \
    echo >&2 "## Help Check" && \
    /tmp/k8s-vault --help


## this stage created final docker image
FROM busybox as release
COPY --from=build /tmp/k8s-vault /k8s-vault
USER nobody
ENTRYPOINT ["/k8s-vault"]
CMD ["--help"]
