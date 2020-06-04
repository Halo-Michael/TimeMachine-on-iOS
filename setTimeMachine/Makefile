export TARGET=iphone:clang::10.3
export ARCHS=arm64 arm64e
export DEBUG=0

include $(THEOS)/makefiles/common.mk

TOOL_NAME = setTimeMachine

$(TOOL_NAME)_FILES = setTimeMachine.m
$(TOOL_NAME)_CFLAGS = -fobjc-arc
$(TOOL_NAME)_LDFLAGS += ../libTimeMachine.tbd
$(TOOL_NAME)_CODESIGN_FLAGS = -S../entitlements-apfs.xml

include $(THEOS_MAKE_PATH)/tool.mk
