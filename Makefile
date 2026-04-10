APP_NAME = MouseStrideDaemon
BUILD_DIR = .build/release
UNIVERSAL_BINARY = .build/universal/$(APP_NAME)
VERSION ?= dev
ZIP_NAME = $(APP_NAME)-$(VERSION).zip
BUNDLE = $(APP_NAME).app
CONTENTS = $(BUNDLE)/Contents
MACOS = $(CONTENTS)/MacOS

ENTITLEMENTS = Sources/MouseStrideDaemon/App/MouseStrideDaemon.entitlements
DEV_ID_APPLICATION ?= $(shell security find-identity -v -p codesigning 2>/dev/null | grep "Developer ID Application" | head -1 | sed -E 's/.*"(.*)"/\1/')
APPLE_ID ?=
APPLE_TEAM_ID ?=
APPLE_APP_PASSWORD ?=

.PHONY: build bundle run build-universal bundle-universal sign notarize staple zip clean

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

sign: bundle-universal
	@if [ -z "$(DEV_ID_APPLICATION)" ]; then \
		echo "ERROR: No 'Developer ID Application' identity found in keychain"; exit 1; \
	fi
	codesign --force --deep --options runtime --timestamp \
		--entitlements $(ENTITLEMENTS) \
		--sign "$(DEV_ID_APPLICATION)" \
		$(BUNDLE)
	codesign --verify --strict --verbose=2 $(BUNDLE)

notarize: sign
	@if [ -z "$(APPLE_ID)" ] || [ -z "$(APPLE_TEAM_ID)" ] || [ -z "$(APPLE_APP_PASSWORD)" ]; then \
		echo "ERROR: APPLE_ID, APPLE_TEAM_ID, APPLE_APP_PASSWORD must be set"; exit 1; \
	fi
	ditto -c -k --sequesterRsrc --keepParent $(BUNDLE) .build/notarize.zip
	xcrun notarytool submit .build/notarize.zip \
		--apple-id "$(APPLE_ID)" \
		--team-id "$(APPLE_TEAM_ID)" \
		--password "$(APPLE_APP_PASSWORD)" \
		--wait
	rm -f .build/notarize.zip

staple: notarize
	xcrun stapler staple $(BUNDLE)
	xcrun stapler validate $(BUNDLE)
	spctl --assess --type execute --verbose=4 $(BUNDLE)

zip: bundle-universal
	@if [ -n "$(APPLE_ID)" ] && [ -n "$(DEV_ID_APPLICATION)" ]; then \
		$(MAKE) staple; \
	else \
		echo "WARNING: building unsigned zip (no DEV_ID_APPLICATION or APPLE_ID set)"; \
	fi
	ditto -c -k --sequesterRsrc --keepParent $(BUNDLE) $(ZIP_NAME)

clean:
	rm -rf .build $(BUNDLE) *.zip
