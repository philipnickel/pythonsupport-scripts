.PHONY: help build test test-components smoke ci format clean

help:
	@echo "Common targets:"
	@echo "  make build      - Build single-file installer to macos-next/dist/"
	@echo "  make test       - Run component tests (utilities + python)"
	@echo "  make smoke      - Build and run integration dry-run"
	@echo "  make ci         - test + build + smoke"
	@echo "  make format     - Format shell scripts with shfmt (if installed)"
	@echo "  make clean      - Remove build artifacts"

build:
	bash macos-next/tools/build.sh

test: test-components

test-components:
	bash macos-next/tests/utilities/precheck.sh
	bash macos-next/tests/components/python.sh
	bash macos-next/tests/components/vscode.sh

smoke: build
	bash macos-next/tests/smoke.sh

ci: test build smoke

format:
	@if command -v shfmt >/dev/null 2>&1; then \
		shfmt -i 2 -ci -sr -w macos-next/src macos-next/tests macos-next/tools ; \
		else echo "shfmt not found; install via 'brew install shfmt' or https://github.com/mvdan/sh"; fi

clean:
	rm -rf macos-next/dist/
