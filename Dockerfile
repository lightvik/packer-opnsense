FROM oraclelinux:10-slim

ARG PACKER_VERSION=1.11.2

# xorriso нужен плагину QEMU для создания CD-ROM-образа с config.xml
# hadolint ignore=DL3041
RUN microdnf install -y \
    curl \
    unzip \
    qemu-kvm \
    qemu-img \
    xorriso \
  && microdnf clean all

RUN curl -fsSL "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" \
    -o /tmp/packer.zip \
  && unzip /tmp/packer.zip -d /usr/local/bin \
  && rm /tmp/packer.zip

WORKDIR /workspace

# Скачиваем плагины заранее, чтобы образ был самодостаточным
COPY plugins.pkr.hcl /workspace/
RUN packer init /workspace/plugins.pkr.hcl

ENTRYPOINT ["packer"]
CMD ["--help"]
