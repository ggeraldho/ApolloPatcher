MODULES = jailed

DEBUG = 0
FINALPACKAGE = 1

TARGET := iphone:clang:latest:12.0

ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ApolloSideloadFix

$(TWEAK_NAME)_FILES = Tweak.x fishhook/fishhook.c
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
_CODESIGN_IPA = 0

include $(THEOS_MAKE_PATH)/tweak.mk
