export ARCHS = arm64 arm64e
export TARGET := iphone::latest:13.0
ADDITIONAL_CFLAGS = -DTHEOS_LEAN_AND_MEAN
INSTALL_TARGET_PROCESSES = SpringBoard imagent tccd

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = iDunnoU
iDunnoU_FILES = Tweak.x $(wildcard *.m)
iDunnoU_EXTRA_FRAMEWORKS = libJCX
iDunnoU_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += idunnoupreferences
include $(THEOS_MAKE_PATH)/aggregate.mk
