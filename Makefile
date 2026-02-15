APP_NAME = MouseFitness
TARGET_NAME = MouseMeasure
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app
CONTENTS = $(APP_BUNDLE)/Contents
MACOS = $(CONTENTS)/MacOS

.PHONY: build bundle run clean

build:
	swift build -c release

bundle: build
	mkdir -p $(MACOS)
	cp $(BUILD_DIR)/$(TARGET_NAME) $(MACOS)/$(APP_NAME)
	cp Sources/MouseMeasure/App/Info.plist $(CONTENTS)/Info.plist

run: bundle
	open $(APP_BUNDLE)

clean:
	rm -rf .build $(APP_BUNDLE)
