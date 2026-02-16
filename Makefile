APP_NAME = MouseStrideDaemon
BUILD_DIR = .build/release
UNIVERSAL_BINARY = .build/universal/$(APP_NAME)
VERSION ?= dev
ZIP_NAME = $(APP_NAME)-$(VERSION).zip
BUNDLE = $(APP_NAME).app
CONTENTS = $(BUNDLE)/Contents
MACOS = $(CONTENTS)/MacOS

.PHONY: build bundle run build-universal bundle-universal zip clean

build:
	swift build -c release --product $(APP_NAME)

bundle: build
	mkdir -p $(MACOS)
	mkdir -p $(CONTENTS)/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(MACOS)/$(APP_NAME)
	cp Sources/MouseStrideDaemon/App/Info.plist $(CONTENTS)/Info.plist
	cp Sources/MouseStrideDaemon/Resources/MouseStride.icns $(CONTENTS)/Resources/MouseStride.icns

run: bundle
	open $(BUNDLE)

build-universal:
	swift build -c release --triple arm64-apple-macosx --product $(APP_NAME)
	swift build -c release --triple x86_64-apple-macosx --product $(APP_NAME)
	mkdir -p .build/universal
	lipo -create \
		.build/arm64-apple-macosx/release/$(APP_NAME) \
		.build/x86_64-apple-macosx/release/$(APP_NAME) \
		-output $(UNIVERSAL_BINARY)

bundle-universal: build-universal
	mkdir -p $(MACOS)
	mkdir -p $(CONTENTS)/Resources
	cp $(UNIVERSAL_BINARY) $(MACOS)/$(APP_NAME)
	cp Sources/MouseStrideDaemon/App/Info.plist $(CONTENTS)/Info.plist
	cp Sources/MouseStrideDaemon/Resources/MouseStride.icns $(CONTENTS)/Resources/MouseStride.icns

zip: bundle-universal
	ditto -c -k --sequesterRsrc --keepParent $(BUNDLE) $(ZIP_NAME)

clean:
	rm -rf .build $(BUNDLE) *.zip
