.PHONY: build check check-submodules format format-check lint test

FIXTURE_ROOT := $(CURDIR)/fixtures
GO_WORK := $(CURDIR)/go.work

build:
	$(MAKE) -C nagi-rs build
	GOWORK=off $(MAKE) -C nagi-go build
	GOWORK=$(GO_WORK) $(MAKE) -C nagitui-go build
	GOWORK=off $(MAKE) -C nagicli-go build

test:
	NAGI_FIXTURES=$(FIXTURE_ROOT) $(MAKE) -C nagi-rs test
	NAGI_FIXTURES=$(FIXTURE_ROOT) GOWORK=off $(MAKE) -C nagi-go test
	NAGI_FIXTURES=$(FIXTURE_ROOT) GOWORK=$(GO_WORK) $(MAKE) -C nagitui-go test
	GOWORK=off $(MAKE) -C nagicli-go test

lint:
	$(MAKE) -C nagi-rs lint
	GOWORK=off $(MAKE) -C nagi-go lint
	GOWORK=$(GO_WORK) $(MAKE) -C nagitui-go lint
	GOWORK=off $(MAKE) -C nagicli-go lint

format:
	$(MAKE) -C nagi-rs format
	$(MAKE) -C nagi-go format
	$(MAKE) -C nagitui-go format

format-check:
	$(MAKE) -C nagi-rs format-check
	$(MAKE) -C nagi-go format-check
	$(MAKE) -C nagitui-go format-check
	$(MAKE) -C nagicli-go format-check

check: check-submodules format-check build test lint

check-submodules:
	sh scripts/check-submodules.sh
