# ── Drain Damage — local development and platform exports ──
SHELL := /bin/sh
.DEFAULT_GOAL := help
HOST_OS := $(shell uname -s)
ifeq ($(HOST_OS),Darwin)
GODOT ?= .tools/Godot.app/Contents/MacOS/Godot
else
GODOT ?= $(if $(wildcard .tools/godot),.tools/godot,godot)
endif
MAC_APP := builds/Drain Damage.app
export GODOT LEVEL MINIBOSS BOSS HERO DIFFICULTY SEED APP SCREENSHOT_MODE
INSTALL_FLAGS ?=

.PHONY: help install install-check install-plan check build build-all build-macos build-android build-ios build-windows run run-preview run-targets run-check editor combat-data

help: ## Show available commands
	@printf '\n\033[1mDrain Damage — available commands:\033[0m\n'
	@awk 'BEGIN { FS = ":.*## " } \
		/^##@ / { printf "\n\033[1;38;5;208m%s\033[0m\n", substr($$0, 5); next } \
		/^[a-zA-Z0-9_-]+:.*## / { printf "  \033[97m%-22s\033[0m %s\n", $$1, $$2 }' \
		$(MAKEFILE_LIST)
	@printf '\n'

##@ Commands
install: ## Install pinned local dependencies (INSTALL_FLAGS=--system permits system packages)
	@printf '📦 Checking host dependencies and installing missing local tools…\n'
	@bash tools/install.sh $(INSTALL_FLAGS)

install-check: ## Check dependencies without changing files, packages or Git settings
	@bash tools/install.sh --check

install-plan: ## Show missing dependencies and planned setup without making changes
	@bash tools/install.sh --dry-run

check: ## Check that Godot is available
	@command -v "$(GODOT)" >/dev/null 2>&1 || { \
		printf '❌ Godot not found. Set GODOT=/path/to/Godot (one executable, no arguments).\n' >&2; exit 1; }
	@"$(GODOT)" --version

build: ## Build for this computer’s OS (macOS currently supported)
ifeq ($(HOST_OS),Darwin)
	@$(MAKE) build-macos
else
	@printf '❌ No native export configured for %s yet. See make help.\n' "$(HOST_OS)" >&2
	@exit 1
endif

build-all: build-macos build-windows ## Build macOS and Windows exports on this Mac

.NOTPARALLEL: build-all

build-macos: check combat-data ## Export and ad-hoc sign the standalone Mac app
	@test "$(HOST_OS)" = Darwin || { printf '❌ Mac packaging requires macOS.\n' >&2; exit 1; }
	@test -f .tools/macos.zip || { printf '❌ Missing Godot export template: .tools/macos.zip\n' >&2; exit 1; }
	@command -v codesign >/dev/null 2>&1 || { printf '❌ codesign is required.\n' >&2; exit 1; }
	@python3 tools/sync_project_version.py
	@printf '📦 Importing assets and exporting macOS…\n'
	@mkdir -p builds
	@"$(GODOT)" --headless --path . --editor --import
	@"$(GODOT)" --headless --path . --export-release macOS "$(MAC_APP)"
	@cp licenses/GODOT_COPYRIGHT.txt "$(MAC_APP)/Contents/Resources/GODOT_COPYRIGHT.txt"
	@codesign --force --deep --sign - "$(MAC_APP)"
	@codesign --verify --deep --strict "$(MAC_APP)"
	@printf '✅ Built %s\n' "$(MAC_APP)"

build-android: ## Planned: Android APK (not configured yet)
	@printf '❌ Android pending: add SDK/JDK, export template, signing and Android preset first.\n' >&2
	@exit 1

build-ios: ## Planned: iOS Xcode project (not configured yet)
	@printf '❌ iOS pending: add Xcode, export template, signing and iOS preset first.\n' >&2
	@exit 1

build-windows: check combat-data ## Export and package Windows x86_64 (no Windows host needed)
	@printf '📦 Exporting and packaging Windows x86_64…\n'
	@python3 -m tools.build_windows

run: combat-data ## Play; optional LEVEL=2-landing and SCREENSHOT_MODE=1 (controller Y freezes without overlays)
	@python3 tools/run_game.py

run-preview: combat-data ## Play in a small agent-test window; accepts the same selectors as run
	@python3 tools/run_game.py --preview

run-targets: ## List implemented level/miniboss/boss launch selectors without opening the game
	@python3 tools/run_game.py --list

run-check: combat-data ## Verify selected target initialization headlessly; optional APP=/path/to/game.app
	@python3 tools/run_game.py --check

editor: check ## Open this project in the Godot editor
	@printf '🛠️ Opening Godot editor…\n'
	@"$(GODOT)" --editor --path .

combat-data: ## Validate canonical combat JSON and generate exportable data
	@python3 tools/build_combat_data.py
	@python3 tools/build_flush_data.py
