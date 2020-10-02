TARGET=JSPlugin
TARGET_BUILD_DIR = /Users/david/Library/Developer/Xcode/DerivedData/Swindler-djalsycogkwxjmfbzxctbsevjvwz/Build/Products/Release
all: target manifest app
	zip -r $(TARGET).zip $(TARGET)

target: $(TARGET)
	mkdir -p $(TARGET)

manifest: Resources/entry.tp
	cp Resources/entry.tp $(TARGET)

app: $(TARGET_BUILD_DIR)/FinaleControl.app
	ln -sf $(TARGET_BUILD_DIR)/FinaleControl.app $(TARGET)
