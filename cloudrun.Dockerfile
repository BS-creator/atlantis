FROM golang:alpine AS builder

ENV TERRAGRUNT_VERSION=0.19.8 \
    TERRAGRUNT_VERSION_SHA256SUM=70e81e5cc7a7c504557103e2ba90ac4c3c90a01bceffb2a34d4419643cf09998 \
    TERRAFORM_VERSION=0.12.3 \
    TERRAFORM_VERSION_SHA256SUM=75e4323b8514074f8c2118ea382fc677c8b1d1730eda323ada222e0fac57f7db

WORKDIR /go/src/github.com/runatlantis/atlantis/

RUN apk --no-cache add \
       curl \
       git \
       dep \
       ca-certificates \
       unzip \
    && curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > terraform_linux_amd64.zip \
    && echo "${TERRAFORM_VERSION_SHA256SUM}  terraform_linux_amd64.zip" > terraform_SHA256SUMS \
    && sha256sum -c terraform_SHA256SUMS \
    && unzip terraform_linux_amd64.zip \
    && curl -sSL https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 > terragrunt \
    && echo "${TERRAGRUNT_VERSION_SHA256SUM}  terragrunt" > terragrunt_SHA256SUMS \
    && sha256sum -c terragrunt_SHA256SUMS \
    && curl -sSL https://github.com/runatlantis/atlantis/releases/download/v0.8.2/atlantis_linux_amd64.zip > atlantis_linux_amd64.zip \
    && unzip atlantis_linux_amd64.zip

#COPY . .

#RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o atlantis .


FROM runatlantis/atlantis:latest
#FROM runatlantis/atlantis:v0.8.2

ARG CLOUD_SDK_VERSION=253.0.0
ENV CLOUD_SDK_VERSION=$CLOUD_SDK_VERSION
ENV PATH /google-cloud-sdk/bin:$PATH

COPY --from=builder /go/src/github.com/runatlantis/atlantis/terraform  /usr/local/bin/terraform
COPY --from=builder /go/src/github.com/runatlantis/atlantis/terragrunt /usr/local/bin/terragrunt
#COPY --from=builder /go/src/github.com/runatlantis/atlantis/atlantis   /usr/local/bin/atlantis

RUN apk --no-cache add \
        curl \
        python \
        py-crcmod \
        bash \
        libc6-compat \
        openssh-client \
        git \
        gnupg \
        ca-certificates \
    && curl -OL https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    && tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    && rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    && ln -s /lib /lib64 \
    && gcloud components install beta \
    && gcloud components install kubectl \
    && gcloud config set core/disable_usage_reporting true \
    && gcloud config set component_manager/disable_update_check true \
    && gcloud config set metrics/environment github_docker_image \
    && gcloud --version

#COPY cloudrun-docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["server"]