APP_NAME = MouseStride
TARGET_NAME = MouseStride
BUILD_DIR = .build/release
UNIVERSAL_BINARY = .build/universal/$(TARGET_NAME)
VERSION ?= dev
DMG_NAME = $(APP_NAME)-$(VERSION).dmg
APP_BUNDLE = $(APP_NAME).app
CONTENTS = $(APP_BUNDLE)/Contents
MACOS = $(CONTENTS)/MacOS

.PHONY: build bundle run build-universal bundle-universal dmg clean

build:
	swift build -c release

bundle: build
	mkdir -p $(MACOS)
	cp $(BUILD_DIR)/$(TARGET_NAME) $(MACOS)/$(APP_NAME)
	cp Sources/MouseStride/App/Info.plist $(CONTENTS)/Info.plist

run: bundle
	open $(APP_BUNDLE)

build-universal:
	swift build -c release --triple arm64-apple-macosx
	swift build -c release --triple x86_64-apple-macosx
	mkdir -p .build/universal
	lipo -create \
		.build/arm64-apple-macosx/release/$(TARGET_NAME) \
		.build/x86_64-apple-macosx/release/$(TARGET_NAME) \
		-output $(UNIVERSAL_BINARY)

bundle-universal: build-universal
	mkdir -p $(MACOS)
	cp $(UNIVERSAL_BINARY) $(MACOS)/$(APP_NAME)
	cp Sources/MouseStride/App/Info.plist $(CONTENTS)/Info.plist

dmg: bundle-universal
	hdiutil create -volname $(APP_NAME) -srcfolder $(APP_BUNDLE) -ov -format UDZO $(DMG_NAME)

clean:
	rm -rf .build $(APP_BUNDLE) *.dmg
