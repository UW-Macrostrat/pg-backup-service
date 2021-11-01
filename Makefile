.PHONY: build test

all: build

build:
	docker build -t ghcr.io/uw-macrostrat/pg-backup-service .

test:
	cd tests && ./test-backup