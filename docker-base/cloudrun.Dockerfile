FROM golang:alpine as builder

ENV GO_WORKDIR /go/src/github.com/veggiemonk/atlantis/
WORKDIR $GO_WORKDIR

RUN set -eux; \
    apk add --no-cache --virtual dep git

ADD . $GO_WORKDIR
RUN dep ensure && CGO_ENABLED=0 GOOS=linux go build -a -tags netgo -ldflags '-w'



FROM alpine:3.9
ARG CLOUD_SDK_VERSION=251.0.0
ENV CLOUD_SDK_VERSION=$CLOUD_SDK_VERSION

ENV PATH /google-cloud-sdk/bin:$PATH
RUN apk --no-cache add \
        curl \
        python \
        py-crcmod \
        bash \
        libc6-compat \
        openssh-client \
        ca-certificates \
        git \
        gnupg \
    && curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    ln -s /lib /lib64 && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image && \
    gcloud --version

RUN set -eux; \
    apk add --no-cache --virtual ca-certificates

# Copy binary from builder stage into image
COPY --from=builder /go/bin/atlantis .

ENTRYPOINT ["cloudrun-entrypoint.sh"]
