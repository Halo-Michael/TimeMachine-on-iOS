ARCHS = arm64 arm64e
TARGET = iPhone:clang:latest:10.0
CFLAGS = -fobjc-arc
LDFLAGS = -F$(THEOS)/frameworks
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = TimeMachineiOS
TimeMachineiOS_FILES = TimeMachineiOS.mm
TimeMachineiOS_INSTALL_PATH = /Library/PreferenceBundles
TimeMachineiOS_CFLAGS = -fobjc-arc
TimeMachineiOS_FRAMEWORKS = UIKit MessageUI Social QuartzCore CoreGraphics
TimeMachineiOS_LDFLAGS += ./Preferences.tbd ./SettingsKit.tbd

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)cp $(THEOS)/include/SettingsKit/Resources/*.png $(THEOS_STAGING_DIR)/Library/PreferenceBundles/TimeMachineiOS.bundle/$(ECHO_END)
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/TimeMachineiOS.plist$(ECHO_END)
