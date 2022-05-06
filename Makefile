SHELL:=/usr/bin/env bash
.SHELLFLAGS := -e -u -o pipefail -c

.PHONY: init
init:
	./scripts/init.sh

.PHONY: linter
linter`:
	./scripts/linter.sh

.PHONY: test
test:
	./scripts/test.sh
