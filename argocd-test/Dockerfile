FROM alpine:3.19

ENV YQ_VERSION=v4.44.3
ENV YQ_PLATFORM=linux_amd64
ENV HELM_VERSION=v3.16.3

# Install required tools
RUN apk --no-cache add bash jq git curl && \
    wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_${YQ_PLATFORM} -O /usr/bin/yq && \
    chmod +x /usr/bin/yq && \
    wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O /tmp/helm.tar.gz && \
    tar -xzf /tmp/helm.tar.gz -C /tmp && \
    mv /tmp/linux-amd64/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf /tmp/helm.tar.gz /tmp/linux-amd64

# Create argocd user (UID 999 required for ArgoCD)
RUN adduser --system --disabled-password --uid 999 argocd

# Create scripts directory
RUN mkdir -p /scripts && chown argocd:root /scripts

# Copy the backstage labeler script
COPY backstage-labeler.sh /scripts/backstage-labeler.sh
RUN chmod +x /scripts/backstage-labeler.sh

USER 999
WORKDIR /home/argocd
