# Copyright (C) 2019 Myles Gray <mg@mylesgray.com>

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

REPO?=mylesagray
IMAGE?=velero

REGISTRY_IMAGE?=$(REPO)/$(IMAGE)
REGISTRY_IMAGE_TAG?=latest

VELERO_VERSION?=v1.1.0
RESTIC_VERSION?=0.9.5

BASE_IMAGE=ubuntu
BASE_IMAGE_TAG=bionic

ARCHS?=amd64 arm32v7 arm64v8
QEMU_ARCHS?=arm aarch64

.PHONY: all qemu wrap build push manifest clean

all:
	make qemu
	make wrap
	make build
	make push
	make manifest
	make clean

help:
	@echo -e "- all : Build, push and build manifests"
	@echo -e "- qemu : Downloads needed qemu static files and preps host"
	@echo -e "- wrap : Creates a wrapper around the base image with qemu added"
	@echo -e "- build : Make the Docker images"
	@echo -e "- push : Publish the images"
	@echo -e "- manifest : Build multiarch manifest"
	@echo -e "- clean : Clean build artifacts"
	@echo -e "Registry: $(REGISTRY_IMAGE)"

build:
	$(foreach arch, $(ARCHS), make build-$(arch);)

build-amd64:
	$(eval ARCH := amd64)
	docker build --rm \
	--build-arg BASE=$(BASE_IMAGE):$(ARCH) \
	--build-arg VELERO_VERSION=$(VELERO_VERSION) \
	--build-arg RESTIC_VERSION=$(RESTIC_VERSION) \
	--build-arg BIN_ARCH=$(ARCH) \
	-f Dockerfile \
	-t $(REGISTRY_IMAGE):$(REGISTRY_IMAGE_TAG)-$(ARCH) .

build-arm32%:
	$(eval ARCH := arm32$*)
	docker build --rm \
	--build-arg BASE=$(BASE_IMAGE):$(ARCH) \
	--build-arg VELERO_VERSION=$(VELERO_VERSION) \
	--build-arg RESTIC_VERSION=$(RESTIC_VERSION) \
	--build-arg BIN_ARCH=arm \
	-f Dockerfile \
	-t $(REGISTRY_IMAGE):$(REGISTRY_IMAGE_TAG)-$(ARCH) .

build-arm64v8:
	$(eval ARCH := arm64v8)
	docker build --rm \
	--build-arg BASE=$(BASE_IMAGE):$(ARCH) \
	--build-arg VELERO_VERSION=$(VELERO_VERSION) \
	--build-arg RESTIC_VERSION=$(RESTIC_VERSION) \
	--build-arg BIN_ARCH=arm64 \
	-f Dockerfile \
	-t $(REGISTRY_IMAGE):$(REGISTRY_IMAGE_TAG)-$(ARCH) .

push:
	$(foreach arch, $(ARCHS), make push-$(arch);)

push-%:
	docker push $(REGISTRY_IMAGE):$(REGISTRY_IMAGE_TAG)-$*

expand-%: # expand architecture variants for manifest
	@if [ "$*" == "amd64" ] ; then \
	   echo '--arch $*'; \
	elif [[ "$*" == *"arm32"* ]] ; then \
	   echo '--arch arm --variant $*' | cut -c 1-21,27-; \
	elif [[ "$*" == *"arm64"* ]] ; then \
	   echo '--arch arm64 --variant arm$*' | cut -c 1-23,29-; \
	fi

manifest:
	docker manifest create --amend $(REGISTRY_IMAGE):$(REGISTRY_IMAGE_TAG) \
		$(foreach arch, $(ARCHS), $(REGISTRY_IMAGE):$(REGISTRY_IMAGE_TAG)-$(arch))
	$(foreach arch, $(ARCHS), \
	docker manifest annotate $(REGISTRY_IMAGE):$(REGISTRY_IMAGE_TAG) \
		$(REGISTRY_IMAGE):$(REGISTRY_IMAGE_TAG)-$(arch) $(shell make expand-$(arch));)
	docker manifest push $(REGISTRY_IMAGE):$(REGISTRY_IMAGE_TAG)

qemu:
	$(foreach arch, $(QEMU_ARCHS), make qemu-$(arch);)

qemu-%:
	-docker run --rm --privileged multiarch/qemu-user-static:register --reset 
	mkdir -p build && cd build/ && \
	curl -L -o qemu-$*-static.tar.gz https://github.com/multiarch/qemu-user-static/releases/download/v4.0.0-5/qemu-$*-static.tar.gz && \
	tar xzf qemu-$*-static.tar.gz && \
	cd ../

wrap:
	$(foreach arch, $(ARCHS), make wrap-$(arch);)

wrap-amd64:
	docker pull amd64/$(BASE_IMAGE):$(BASE_IMAGE_TAG)
	docker tag amd64/$(BASE_IMAGE):$(BASE_IMAGE_TAG) $(BASE_IMAGE):amd64

wrap-%:
	$(eval ARCH := $*)
	docker build \
		--build-arg ARCH=$(ARCH) \
		--build-arg BASE=$(ARCH)/$(BASE_IMAGE):$(BASE_IMAGE_TAG) \
		-t $(BASE_IMAGE):$(ARCH) -f qemu/Dockerfile .

clean:
	-docker rm -fv $$(docker ps -a -q -f status=exited)
	-docker rmi -f $$(docker images -q -f dangling=true)
	-$(foreach arch, $(ARCHS), docker rmi -f $(arch)/$(BASE_IMAGE):$(BASE_IMAGE_TAG);)
	-$(foreach arch, $(ARCHS), docker rmi -f $(BASE_IMAGE):$(arch);)
	-rm -rf build/
	-docker rmi -f multiarch/qemu-user-static:register
	-docker rmi -f $$(docker images --format '{{.Repository}}:{{.Tag}}' | grep $(REGISTRY_IMAGE))