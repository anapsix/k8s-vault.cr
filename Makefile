UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  OS:= darwin
endif
ifeq ($(UNAME_S),Linux)
  OS:= linux
endif
UNAME_M:= $(shell uname -m)
ifeq ($(UNAME_M), x86_64)
  ARCH ?= amd64
else ifeq ($(UNAME_M), arm64)
  ARCH ?= arm64
else ifeq ($(UNAME_M), aarch64)
  ARCH ?= arm64
else
  $(error the "$(UNAME_M)" arch is not supported)
endif

BINARY:= k8s-vault
VERSION:= $(shell cat VERSION)
TARGET:= src/cli
RELEASE_DIR:= releases
OUTPUT:= ./$(RELEASE_DIR)/$(BINARY)-$(VERSION)-$(OS)-$(ARCH)

.PHONY: all clean version prepare help

all: clean prepare releases ## Builds everything

help: ## Show this help
	@echo
	@printf '\033[34mtargets:\033[0m\n'
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) |\
		sort |\
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

releases: prepare version $(TARGET) pack docker docker_arm64 ## Builds releases
	docker run -it --rm --platform linux/amd64 -v ${PWD}/$(RELEASE_DIR):/app --entrypoint "sh" $(BINARY):$(VERSION)-amd64 -c "cp /bin/$(BINARY) /app/$(BINARY)-$(VERSION)-linux-amd64"
	docker run -it --rm --platform linux/arm64 -v ${PWD}/$(RELEASE_DIR):/app --entrypoint "sh" $(BINARY):$(VERSION)-arm64 -c "cp /bin/$(BINARY) /app/$(BINARY)-$(VERSION)-linux-arm64"

docker: ## Builds docker image amd64
	docker build --platform linux/amd64 -t $(BINARY):$(VERSION)-amd64 .
	docker tag $(BINARY):$(VERSION)-amd64 $(BINARY):latest-amd64

docker_arm64: ## Builds docker image for arm64
	docker build --platform linux/arm64 -t $(BINARY):$(VERSION)-arm64 .
	docker tag $(BINARY):$(VERSION)-arm64 $(BINARY):latest-arm64

prepare:
	@if [ ! -d ./$(RELEASE_DIR) ]; then mkdir ./$(RELEASE_DIR); fi

clean: ## Removes release directory
	@rm -f ./$(RELEASE_DIR)/*
	@echo >&2 "cleaned up"

version: ## Updates the version
	@sed -i "" 's/^version:.*/version: "$(VERSION)"/g' k8s-vault_example.yaml
	@sed -i "" 's/^version:.*/version: $(VERSION)/g' shard.yml
	@echo "shard.yml updated with version $(VERSION)"

$(TARGET): % : prepare $(filter-out $(TEMPS), $(OBJ)) %.cr
	@crystal build src/cli.cr -o $(OUTPUT) --progress --release
	@rm ./$(RELEASE_DIR)/*.dwarf
	@echo "compiled binaries placed to \"./$(RELEASE_DIR)\" directory"

pack: ## Runs UPX on locally built binary
	@find ./$(RELEASE_DIR) -type f -name "$(BINARY)-$(VERSION)-$(OS)-$(ARCH)" | xargs upx
