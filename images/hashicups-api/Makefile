.PHONY: build build_and_push

DOCKER_REPOSITORY ?= danielehc
DOCKER_IMAGE ?= hashicups-api
TAG=`date +%Y-%m-%d`

APP1_VERSION="v0.0.7" # Public API https://hub.docker.com/r/hashicorpdemoapp/public-api/tags
APP2_VERSION="v0.0.22" # Product API https://hub.docker.com/r/hashicorpdemoapp/product-api/tags
APP3_VERSION="v0.0.16" # Payments
BASE_VERSION=latest

build:
	DOCKER_BUILDKIT=1 docker build \
	--build-arg APP1_VERSION=${APP1_VERSION} \
	--build-arg APP2_VERSION=${APP2_VERSION} \
	--build-arg APP3_VERSION=${APP3_VERSION} \
    --build-arg BASE_VERSION=${BASE_VERSION} \
	-t "$(DOCKER_REPOSITORY)/${DOCKER_IMAGE}:$(TAG)" .

build_and_push: build
	docker push "$(DOCKER_REPOSITORY)/${DOCKER_IMAGE}:$(TAG)"

latest:	
	DOCKER_BUILDKIT=1 docker build \
	--build-arg APP1_VERSION=${APP1_VERSION} \
	--build-arg APP2_VERSION=${APP2_VERSION} \
	--build-arg APP3_VERSION=${APP3_VERSION} \
    --build-arg BASE_VERSION=${BASE_VERSION} \
	-t "$(DOCKER_REPOSITORY)/${DOCKER_IMAGE}:latest" . && \
	docker push "$(DOCKER_REPOSITORY)/${DOCKER_IMAGE}:latest"