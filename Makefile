SHELL := /bin/bash
.DEFAULT_GOAL := help

.PHONY: help doctor tools generate build test backend-check clean
help:
	@printf '%s\n' 'ATHEER developer commands:' '  make doctor    Check local prerequisites' '  make generate  Generate the Xcode project' '  make build     Build the macOS app' '  make test      Run macOS tests' '  make backend-check Run API typecheck and tests' '  make clean     Remove generated build artifacts'
doctor:
	@bash scripts/doctor.sh
tools:
	@bash scripts/install-xcodegen.sh
generate: tools
	@cd apps/macos/ATHEERTradingPro && $(HOME)/.local/bin/xcodegen generate
build: generate
	@bash scripts/build-macos.sh
test: generate
	@bash scripts/test-macos.sh
clean:
	@rm -rf .build build DerivedData apps/macos/ATHEERTradingPro/ATHEERTradingPro.xcodeproj

backend-check:
	@cd services/api && npm ci --ignore-scripts --no-audit --no-fund && npm run typecheck && npm test
