ARG DIGEST=sha256:c530ca8805f8cae3e469e12d985531f8d2ac259e150f935abf80339ea055ccbe

FROM docker.io/bitnami/kubectl:1.26.2 as kubectl

FROM registry.access.redhat.com/ubi8-micro@${DIGEST}

COPY --from=kubectl /opt/bitnami/kubectl/bin/kubectl /usr/bin/kubectl

LABEL org.opencontainers.image.source https://github.com/shanduur/template-ci-container
LABEL org.opencontainers.image.authors "shanduur <mateusz.urbanek.98@gmail.com>"

RUN echo "Hello World"
