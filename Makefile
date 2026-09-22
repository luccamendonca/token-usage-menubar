APP = ClaudeUsageToolbar
BINARY = TokenUsageMenubar
BUNDLE = build/$(APP).app
INSTALL_DIR = /Applications
INSTALLED = $(INSTALL_DIR)/$(APP).app
LABEL = dev.personal.ClaudeUsageToolbar
PLIST = $(HOME)/Library/LaunchAgents/$(LABEL).plist
UID := $(shell id -u)

.PHONY: build app run install uninstall clean

build:
	swift build -c release

app: build
	mkdir -p "$(BUNDLE)/Contents/MacOS"
	cp "$$(swift build -c release --show-bin-path)/$(BINARY)" "$(BUNDLE)/Contents/MacOS/$(BINARY)"
	cp Support/Info.plist "$(BUNDLE)/Contents/Info.plist"
	codesign --force --sign - "$(BUNDLE)" >/dev/null 2>&1 || true

run: app
	open $(BUNDLE)

# Copy the bundle to /Applications and register a LaunchAgent so it starts at
# login. The plist lives outside build/ so `make clean` can't break autostart.
install: app
	launchctl bootout gui/$(UID)/$(LABEL) 2>/dev/null || true
	pkill -x $(BINARY) 2>/dev/null || true
	rm -rf "$(INSTALLED)"
	cp -R "$(BUNDLE)" "$(INSTALL_DIR)/"
	mkdir -p "$(HOME)/Library/LaunchAgents"
	sed 's|@APP_BINARY@|$(INSTALLED)/Contents/MacOS/$(BINARY)|' \
		Support/$(LABEL).plist > "$(PLIST)"
	launchctl bootstrap gui/$(UID) "$(PLIST)"
	@echo "installed at $(INSTALLED), autostart enabled ($(LABEL))"

uninstall:
	launchctl bootout gui/$(UID)/$(LABEL) 2>/dev/null || true
	pkill -x $(BINARY) 2>/dev/null || true
	rm -f "$(PLIST)"
	rm -rf "$(INSTALLED)"
	@echo "uninstalled"

clean:
	rm -rf build .build
