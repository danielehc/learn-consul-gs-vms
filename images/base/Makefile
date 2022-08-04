.PHONY: build build_and_push

DOCKER_REPOSITORY ?= danielehc
DOCKER_IMAGE ?= instruqt-base
TAG=`date +%Y-%m-%d`

build:
	DOCKER_BUILDKIT=1 docker build -t "$(DOCKER_REPOSITORY)/${DOCKER_IMAGE}:$(TAG)" .

build_and_push: build
	docker push "$(DOCKER_REPOSITORY)/${DOCKER_IMAGE}:$(TAG)"

latest:	
	DOCKER_BUILDKIT=1 docker build -t "$(DOCKER_REPOSITORY)/${DOCKER_IMAGE}:latest" . && \
	docker push "$(DOCKER_REPOSITORY)/${DOCKER_IMAGE}:latest"