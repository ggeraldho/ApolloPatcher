DEBUG = 0
FINALPACKAGE = 1

ARCHS = arm64

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
TARGET = iphone:16.2:15.0
else
TARGET = iphone:14.5:12.0
endif

INSTALL_TARGET_PROCESSES = Apollo

THEOS_DEVICE_IP = 192.168.0.11

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ApolloPatcher

$(TWEAK_NAME)_FILES = Tweak.x
$(TWEAK_NAME)_FRAMEWORKS = UIKit
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
