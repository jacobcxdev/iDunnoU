ARCHS = arm64 arm64e
TARGET = iphone::13.0
INSTALL_TARGET_PROCESSES = MobileSMS Preferences

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = iDunnoU

iDunnoU_FILES = Tweak.x
iDunnoU_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += idunnoupreferences
include $(THEOS_MAKE_PATH)/aggregate.mk
