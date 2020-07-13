include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = TimeMachine

TimeMachine_FILES = TimeMachineRootListController.m
TimeMachine_INSTALL_PATH = /Library/PreferenceBundles
TimeMachine_FRAMEWORKS = UIKit
TimeMachine_PRIVATE_FRAMEWORKS = Preferences
TimeMachine_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/TimeMachine.plist$(ECHO_END)
