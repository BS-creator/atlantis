FROM golang:alpine AS builder

ENV TERRAGRUNT_VERSION=0.19.16 \
    TERRAGRUNT_VERSION_SHA256SUM=c5187d23dc536631fc21b69d05a977b5ddceccaa79c4f096f6abd1c526bc6b6b \
    TERRAFORM_VERSION=0.12.6 \
    TERRAFORM_VERSION_SHA256SUM=6544eb55b3e916affeea0a46fe785329c36de1ba1bdb51ca5239d3567101876f

WORKDIR /app

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
    && chmod +x terragrunt

FROM runatlantis/atlantis:latest
#FROM runatlantis/atlantis:v0.8.2

ARG CLOUD_SDK_VERSION=256.0.0
ENV CLOUD_SDK_VERSION=$CLOUD_SDK_VERSION
ENV PATH /google-cloud-sdk/bin:$PATH

COPY --from=builder /app/terraform  /usr/local/bin/terraform_
COPY --from=builder /app/terragrunt /usr/local/bin/terragrunt

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
    && gcloud --version \
    && chmod +x /usr/local/bin/terragrunt \
    && chmod +x /usr/local/bin/terraform_ 

#COPY cloudrun-docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["server"]