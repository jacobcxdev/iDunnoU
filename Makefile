FINALPACKAGE = 1

ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = MobileSMS
TARGET = iphone::13.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = iDunnoU

iDunnoU_FILES = Tweak.x
iDunnoU_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
