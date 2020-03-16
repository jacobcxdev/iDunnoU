include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = iDunnoUPreferences

iDunnoUPreferences_FILES = $(wildcard *.m)
iDunnoUPreferences_INSTALL_PATH = /Library/PreferenceBundles
iDunnoUPreferences_FRAMEWORKS = UIKit
iDunnoUPreferences_PRIVATE_FRAMEWORKS = Preferences
iDunnoUPreferences_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/iDunnoUPreferences.plist$(ECHO_END)
