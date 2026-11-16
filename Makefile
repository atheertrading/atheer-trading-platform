SHELL := /bin/bash
.DEFAULT_GOAL := help

.PHONY: help doctor generate build test clean
help:
	@printf '%s\n' 'ATHEER developer commands:' '  make doctor    Check local prerequisites' '  make generate  Generate the Xcode project' '  make build     Build the macOS app' '  make test      Run macOS tests' '  make clean     Remove generated build artifacts'
doctor:
	@bash scripts/doctor.sh
generate:
	@cd apps/macos/ATHEERTradingPro && xcodegen generate
build: generate
	@bash scripts/build-macos.sh
test: generate
	@bash scripts/test-macos.sh
clean:
	@rm -rf .build build DerivedData apps/macos/ATHEERTradingPro/ATHEERTradingPro.xcodeproj
