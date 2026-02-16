APP_NAME = MouseStride
TARGET_NAME = MouseStride
DAEMON_NAME = MouseStrideDaemon
BUILD_DIR = .build/release
UNIVERSAL_BINARY = .build/universal/$(TARGET_NAME)
UNIVERSAL_DAEMON = .build/universal/$(DAEMON_NAME)
VERSION ?= dev
DMG_NAME = $(APP_NAME)-$(VERSION).dmg
DAEMON_ZIP = $(DAEMON_NAME)-$(VERSION).zip
APP_BUNDLE = $(APP_NAME).app
DAEMON_BUNDLE = $(DAEMON_NAME).app
CONTENTS = $(APP_BUNDLE)/Contents
MACOS = $(CONTENTS)/MacOS
DAEMON_CONTENTS = $(DAEMON_BUNDLE)/Contents
DAEMON_MACOS = $(DAEMON_CONTENTS)/MacOS

.PHONY: build bundle run build-universal bundle-universal dmg daemon-build daemon-bundle daemon-run daemon-build-universal daemon-bundle-universal daemon-zip clean

build:
	swift build -c release

bundle: build
	mkdir -p $(MACOS)
	mkdir -p $(CONTENTS)/Resources
	cp $(BUILD_DIR)/$(TARGET_NAME) $(MACOS)/$(APP_NAME)
	cp Sources/MouseStride/App/Info.plist $(CONTENTS)/Info.plist
	cp Sources/MouseStride/Resources/MouseStride.icns $(CONTENTS)/Resources/MouseStride.icns

run: bundle
	open $(APP_BUNDLE)

build-universal:
	swift build -c release --triple arm64-apple-macosx --product $(TARGET_NAME)
	swift build -c release --triple x86_64-apple-macosx --product $(TARGET_NAME)
	mkdir -p .build/universal
	lipo -create \
		.build/arm64-apple-macosx/release/$(TARGET_NAME) \
		.build/x86_64-apple-macosx/release/$(TARGET_NAME) \
		-output $(UNIVERSAL_BINARY)

bundle-universal: build-universal
	mkdir -p $(MACOS)
	mkdir -p $(CONTENTS)/Resources
	cp $(UNIVERSAL_BINARY) $(MACOS)/$(APP_NAME)
	cp Sources/MouseStride/App/Info.plist $(CONTENTS)/Info.plist
	cp Sources/MouseStride/Resources/MouseStride.icns $(CONTENTS)/Resources/MouseStride.icns

dmg: bundle-universal
	hdiutil create -volname $(APP_NAME) -srcfolder $(APP_BUNDLE) -ov -format UDZO $(DMG_NAME)

# Daemon targets

daemon-build:
	swift build -c release --product $(DAEMON_NAME)

daemon-bundle: daemon-build
	mkdir -p $(DAEMON_MACOS)
	mkdir -p $(DAEMON_CONTENTS)/Resources
	cp $(BUILD_DIR)/$(DAEMON_NAME) $(DAEMON_MACOS)/$(DAEMON_NAME)
	cp Sources/MouseStrideDaemon/App/Info.plist $(DAEMON_CONTENTS)/Info.plist
	cp Sources/MouseStrideDaemon/Resources/MouseStride.icns $(DAEMON_CONTENTS)/Resources/MouseStride.icns

daemon-run: daemon-bundle
	open $(DAEMON_BUNDLE)

daemon-build-universal:
	swift build -c release --triple arm64-apple-macosx --product $(DAEMON_NAME)
	swift build -c release --triple x86_64-apple-macosx --product $(DAEMON_NAME)
	mkdir -p .build/universal
	lipo -create \
		.build/arm64-apple-macosx/release/$(DAEMON_NAME) \
		.build/x86_64-apple-macosx/release/$(DAEMON_NAME) \
		-output $(UNIVERSAL_DAEMON)

daemon-bundle-universal: daemon-build-universal
	mkdir -p $(DAEMON_MACOS)
	mkdir -p $(DAEMON_CONTENTS)/Resources
	cp $(UNIVERSAL_DAEMON) $(DAEMON_MACOS)/$(DAEMON_NAME)
	cp Sources/MouseStrideDaemon/App/Info.plist $(DAEMON_CONTENTS)/Info.plist
	cp Sources/MouseStrideDaemon/Resources/MouseStride.icns $(DAEMON_CONTENTS)/Resources/MouseStride.icns

daemon-zip: daemon-bundle-universal
	ditto -c -k --sequesterRsrc --keepParent $(DAEMON_BUNDLE) $(DAEMON_ZIP)

clean:
	rm -rf .build $(APP_BUNDLE) $(DAEMON_BUNDLE) *.dmg *.zip
