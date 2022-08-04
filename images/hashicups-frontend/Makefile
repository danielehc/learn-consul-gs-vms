.PHONY: build build_and_push

DOCKER_REPOSITORY ?= danielehc
DOCKER_IMAGE ?= hashicups-frontend
TAG=`date +%Y-%m-%d`

# CONSUL_VERSION=latest
# ENVOY_VERSION=1.12-latest
APP_VERSION="v1.0.5" # https://hub.docker.com/r/hashicorpdemoapp/frontend/tags
BASE_VERSION=latest

build:
	DOCKER_BUILDKIT=1 docker build \
	--build-arg APP_VERSION=${APP_VERSION} \
    --build-arg BASE_VERSION=${BASE_VERSION} \
	-t "$(DOCKER_REPOSITORY)/${DOCKER_IMAGE}:$(TAG)" .

build_and_push: build
	docker push "$(DOCKER_REPOSITORY)/${DOCKER_IMAGE}:$(TAG)"

latest:	
	DOCKER_BUILDKIT=1 docker build \
	--build-arg APP_VERSION=${APP_VERSION} \
    --build-arg BASE_VERSION=${BASE_VERSION} \
	-t "$(DOCKER_REPOSITORY)/${DOCKER_IMAGE}:latest" . && \
	docker push "$(DOCKER_REPOSITORY)/${DOCKER_IMAGE}:latest"