TARGET = iphone:7.1:2.0
ARCHS = arm64 armv7
CFLAGS = -Wno-error
GO_EASY_ON_ME = 1

include theos/makefiles/common.mk

TWEAK_NAME = Symbolicator
Symbolicator_FILES = Tweak.xm Symbolicator.mm
Symbolicator_PRIVATE_FRAMEWORKS = Symbolication

include $(THEOS_MAKE_PATH)/tweak.mk

