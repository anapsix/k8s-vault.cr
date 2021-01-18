UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  OS:= darwin
endif
ifeq ($(UNAME_S),Linux)
  OS:= linux
endif
UNAME_M:= $(shell uname -m)
ifeq ($(UNAME_M),x86_64)
  ARCH:= amd64
endif

BINARY:= k8s-vault
VERSION:= $(shell cat VERSION)
TARGET:= src/cli
RELEASE_DIR:= releases
OUTPUT:= ./$(RELEASE_DIR)/$(BINARY)-$(VERSION)-$(OS)-$(ARCH)

.PHONY: all clean version prepare

all: clean prepare releases

releases: prepare version $(TARGET) pack docker
	docker run -it --rm -v ${PWD}/$(RELEASE_DIR):/app --entrypoint "sh" $(BINARY):$(VERSION) -c "cp /$(BINARY) /app/$(BINARY)-$(VERSION)-linux-amd64"

docker:
	docker build -t $(BINARY):$(VERSION) .
	docker tag $(BINARY):$(VERSION) $(BINARY):latest

prepare:
	@if [ ! -d ./$(RELEASE_DIR) ]; then mkdir ./$(RELEASE_DIR); fi

clean:
	@rm -f ./$(RELEASE_DIR)/*
	@echo >&2 "cleaned up"

version:
	@sed -i "" 's/^version:.*/version: $(VERSION)/g' shard.yml
	@echo "shard.yml updated with version $(VERSION)"

$(TARGET): % : prepare $(filter-out $(TEMPS), $(OBJ)) %.cr
	@crystal build src/cli.cr -o $(OUTPUT) --progress --release
	@rm ./$(RELEASE_DIR)/*.dwarf
	@echo "compiled binaries places to \"./$(RELEASE_DIR)\" directory"

pack:
	@find ./$(RELEASE_DIR) -type f -name "$(BINARY)-$(VERSION)-$(OS)-$(ARCH)" | xargs upx
