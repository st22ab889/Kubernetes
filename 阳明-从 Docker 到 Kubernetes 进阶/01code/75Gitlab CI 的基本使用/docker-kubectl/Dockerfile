# 不需要下载 kubectl,在构建镜像的过程中自动下载

FROM alpine:3.8

MAINTAINER aaron <kkk_en@163.com>

# 在这里指定需要的 kubectl 版本
ARG KUBE_VERSION="v1.18.10"

RUN apk add --update ca-certificates \
 && apk add --update -t deps curl \
 && apk add --update gettext \
 && apk add --update git \
 && curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
 && chmod +x /usr/local/bin/kubectl \
 && apk del --purge deps \
 && rm /var/cache/apk/*

 ENTRYPOINT ["kubectl"]
 CMD ["--help"]