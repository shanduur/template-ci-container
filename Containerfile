ARG DIGEST=sha256:c530ca8805f8cae3e469e12d985531f8d2ac259e150f935abf80339ea055ccbe
FROM registry.access.redhat.com/ubi8-micro@${DIGEST}

RUN echo "Hello World"
