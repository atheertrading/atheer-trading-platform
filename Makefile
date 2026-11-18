SHELL := /bin/bash
REPOSITORY_DIR ?= $(CURDIR)

.PHONY: help doctor tools sync bootstrap generate build test app-run backend-setup backend-check backend-start safe-sync-test clean

help:
	@printf '%s\n' \
	  'make doctor          Check local prerequisites and repository state (read-only)' \
	  'make sync            Safely fast-forward local main and preserve local work' \
	  'make bootstrap       Sync, verify tools, install backend dependencies, generate Xcode project' \
	  'make generate        Generate the Xcode project from project.yml' \
	  'make build           Build the macOS application' \
	  'make test            Run macOS XCTest suite' \
	  'make app-run         Build and request launch of the macOS application' \
	  'make backend-setup   Install locked backend development dependencies' \
	  'make backend-check   Typecheck and test the backend API' \
	  'make backend-start   Run the loopback-only backend with a temporary private IPC capability' \
	  'make safe-sync-test  Test non-destructive local synchronization in a temporary Git repository' \
	  'make clean           Remove local build artifacts only'

doctor:
	@bash scripts/doctor.sh

tools:
	@bash scripts/install-xcodegen.sh

sync:
	@bash scripts/safe-sync.sh "$(REPOSITORY_DIR)"

bootstrap:
	@bash scripts/bootstrap-local.sh "$(REPOSITORY_DIR)"

generate: tools
	@cd apps/macos/ATHEERTradingPro && "$(HOME)/.local/bin/xcodegen" generate

build: generate
	@bash scripts/build-macos.sh

test: generate
	@bash scripts/test-macos.sh

app-run: build
	@bash scripts/run-macos.sh

backend-setup:
	@cd services/api && npm ci --ignore-scripts --no-audit --no-fund

backend-check: backend-setup
	@cd services/api && npm run typecheck && npm test

backend-start:
	@test -x services/api/node_modules/.bin/tsc || { echo 'Run make backend-setup first.' >&2; exit 2; }
	@bash scripts/backend-dev.sh

safe-sync-test:
	@bash scripts/tests/test-safe-sync.sh

clean:
	@rm -rf .build build DerivedData
