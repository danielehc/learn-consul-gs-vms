.PHONY: build build_and_push

DOCKER_REPOSITORY ?= danielehc
DOCKER_IMAGE ?= instruqt-base-consul
TAG=`date +%Y-%m-%d`

CONSUL_VERSION=1.12.4
ENVOY_VERSION=1.21-latest
BASE_VERSION=latest

build:
	DOCKER_BUILDKIT=1 docker build \
	--build-arg CONSUL_VERSION=${CONSUL_VERSION} \
    --build-arg ENVOY_VERSION=v${ENVOY_VERSION} \
    --build-arg BASE_VERSION=${BASE_VERSION} \
	-t "$(DOCKER_REPOSITORY)/${DOCKER_IMAGE}:$(TAG)" .

build_and_push: build
	docker push "$(DOCKER_REPOSITORY)/${DOCKER_IMAGE}:$(TAG)"

latest:	
	DOCKER_BUILDKIT=1 docker build \
	--build-arg CONSUL_VERSION=${CONSUL_VERSION} \
    --build-arg ENVOY_VERSION=v${ENVOY_VERSION} \
    --build-arg BASE_VERSION=${BASE_VERSION} \
	-t "$(DOCKER_REPOSITORY)/${DOCKER_IMAGE}:latest" . && \
	docker push "$(DOCKER_REPOSITORY)/${DOCKER_IMAGE}:latest"