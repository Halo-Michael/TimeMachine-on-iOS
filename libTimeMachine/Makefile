export TARGET=iphone:clang::10.3
export ARCHS=arm64 arm64e
export DEBUG=0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libTimeMachine
$(LIBRARY_NAME)_FILES = libTimeMachine.c libTimeMachine.m

include $(THEOS_MAKE_PATH)/library.mk