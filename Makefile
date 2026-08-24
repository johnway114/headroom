APP_NAME     := Headroom
APP_BUNDLE   := $(APP_NAME).app
BUILD_DIR    := .build
RELEASE_BIN  := $(BUILD_DIR)/release/$(APP_NAME)
STAGED_APP   := $(BUILD_DIR)/$(APP_BUNDLE)
PREFIX       := $(HOME)/Applications
INSTALL_APP  := $(PREFIX)/$(APP_BUNDLE)
BUNDLE_ID    := com.johnconway.headroom

.PHONY: build test app install uninstall open restart clean

build:
	swift build -c release --product $(APP_NAME)

test:
	swift test

app: build
	rm -rf "$(STAGED_APP)"
	mkdir -p "$(STAGED_APP)/Contents/MacOS"
	cp "$(RELEASE_BIN)" "$(STAGED_APP)/Contents/MacOS/$(APP_NAME)"
	cp Info.plist "$(STAGED_APP)/Contents/Info.plist"
	printf 'APPL????' > "$(STAGED_APP)/Contents/PkgInfo"
	codesign --force --sign - --identifier "$(BUNDLE_ID)" "$(STAGED_APP)"

install: app
	mkdir -p "$(PREFIX)"
	-killall $(APP_NAME) 2>/dev/null || true
	rm -rf "$(INSTALL_APP)"
	cp -R "$(STAGED_APP)" "$(INSTALL_APP)"
	xattr -dr com.apple.quarantine "$(INSTALL_APP)" 2>/dev/null || true

open: install
	open "$(INSTALL_APP)"

restart: install
	open "$(INSTALL_APP)"

uninstall:
	-killall $(APP_NAME) 2>/dev/null || true
	rm -rf "$(INSTALL_APP)"

clean:
	swift package clean
	rm -rf "$(STAGED_APP)"
