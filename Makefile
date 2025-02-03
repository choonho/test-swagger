TARGET ?= all
VERSION ?= v1
TAG ?= 0.4
DOCKER_NAME ?= cloudeco/api_builder:${TAG}
PLATFORM ?= linux/arm64,linux/amd64

.PHONY: help all python go gateway json clean

define banner
	@echo "========================================================================"
	@echo " $(1)"
	@echo "========================================================================"
endef

define set_build_env
	git submodule update --init --recursive
	docker buildx build --platform=${PLATFORM} -t ${DOCKER_NAME} .
	docker push ${DOCKER_NAME}
endef

define build
	$(call banner, "Start the build protobuf")
	docker run -i --rm -v ${PWD}:/opt ${DOCKER_NAME} python3 build.py ${TARGET} -c$(1)
endef

help:
	@echo "Make Options:"
	@echo " all                 - Generate all"
	@echo " python              - Generate python protobuf"
	@echo " go                  - Generate go protobuf"
	@echo " openapi             - Generate API artifact json files"
	@echo " docker              - Build Protobuf build image"
	@echo " clean               - Clean up dist directory"

docker:
	$(call banner, "Generate Protobuf Build Image")
	$(call set_build_env)

all:
	$(call banner, "Generate all : ${TARGET}")
	$(call build, "all")

openapi:
	$(call banner, "Generate OpenAPIv2 json files")
	$(call build, "openapi")
	docker run -i --rm -v ${PWD}:/opt ${DOCKER_NAME} python3 merge_swagger.py

python:
	$(call banner, "Generate python protobuf")
	$(call build, "python")

go:
	$(call banner, "Generate go protobuf")
	$(call build, "go")

clean:
	$(call banner, "Clean up dist directory")
	rm -rf dist
