VERSION = 0.12.0
Package = com.michael.timemachine
SDK = ${THEOS}/sdks/iPhoneOS14.3.sdk
CC = xcrun -sdk $(SDK) clang -arch arm64 -arch arm64e -miphoneos-version-min=10.3 -Os
LDID = ldid

.PHONY: all clean

all: clean libTimeMachine postinst prerm TimeMachineRootListController snapshotcheck setTimeMachine TimeMachine
	mkdir $(Package)_$(VERSION)_iphoneos-arm
	mkdir $(Package)_$(VERSION)_iphoneos-arm/DEBIAN
	cp control $(Package)_$(VERSION)_iphoneos-arm/DEBIAN
	mv postinst prerm $(Package)_$(VERSION)_iphoneos-arm/DEBIAN
	mkdir $(Package)_$(VERSION)_iphoneos-arm/etc
	mkdir $(Package)_$(VERSION)_iphoneos-arm/etc/rc.d
	mv snapshotcheck $(Package)_$(VERSION)_iphoneos-arm/etc/rc.d
	mkdir $(Package)_$(VERSION)_iphoneos-arm/Library
	mkdir $(Package)_$(VERSION)_iphoneos-arm/Library/LaunchDaemons
	cp com.michael.TimeMachine.plist $(Package)_$(VERSION)_iphoneos-arm/Library/LaunchDaemons
	mkdir $(Package)_$(VERSION)_iphoneos-arm/usr
	mkdir $(Package)_$(VERSION)_iphoneos-arm/usr/bin
	mv setTimeMachine $(Package)_$(VERSION)_iphoneos-arm/usr/bin
	mkdir $(Package)_$(VERSION)_iphoneos-arm/usr/lib
	mv libTimeMachine.dylib $(Package)_$(VERSION)_iphoneos-arm/usr/lib
	mkdir $(Package)_$(VERSION)_iphoneos-arm/Library/PreferenceBundles
	mkdir $(Package)_$(VERSION)_iphoneos-arm/Library/PreferenceLoader
	mkdir $(Package)_$(VERSION)_iphoneos-arm/Library/PreferenceLoader/Preferences
	cp -r Resources $(Package)_$(VERSION)_iphoneos-arm/Library/PreferenceBundles/TimeMachine.bundle
	mv TimeMachineRootListController $(Package)_$(VERSION)_iphoneos-arm/Library/PreferenceBundles/TimeMachine.bundle/TimeMachine
	cp entry.plist $(Package)_$(VERSION)_iphoneos-arm/Library/PreferenceLoader/Preferences/TimeMachine.plist
	mkdir $(Package)_$(VERSION)_iphoneos-arm/usr/libexec
	mv TimeMachine $(Package)_$(VERSION)_iphoneos-arm/usr/libexec
	dpkg -b $(Package)_$(VERSION)_iphoneos-arm

libTimeMachine: clean
	$(CC) -dynamiclib -install_name /usr/lib/libTimeMachine.dylib -compatibility_version $(VERSION) -current_version $(VERSION) -framework CoreFoundation -framework IOKit libTimeMachine.c -o libTimeMachine.dylib
	strip -x libTimeMachine.dylib
	$(LDID) -S libTimeMachine.dylib

postinst: libTimeMachine
	$(CC) -fobjc-arc -framework Foundation libTimeMachine.dylib postinst.m -o postinst
	strip postinst
	$(LDID) -Sentitlements-apfs.xml postinst

prerm: libTimeMachine
	$(CC) -framework CoreFoundation libTimeMachine.dylib prerm.c -o prerm
	strip prerm
	$(LDID) -Sentitlements-apfs.xml prerm

snapshotcheck: libTimeMachine
	$(CC) -fobjc-arc -framework Foundation libTimeMachine.dylib snapshotcheck.m -o snapshotcheck
	strip snapshotcheck
	$(LDID) -Sentitlements-apfs.xml snapshotcheck

TimeMachineRootListController: libTimeMachine
	$(CC) -dynamiclib -fobjc-arc -install_name /Library/PreferenceBundles/TimeMachine.bundle/TimeMachine -I${THEOS}/vendor/include/ -framework Foundation -F $(SDK)/System/Library/PrivateFrameworks -framework Preferences libTimeMachine.dylib TimeMachineRootListController.m -o TimeMachineRootListController
	strip -x TimeMachineRootListController
	$(LDID) -S TimeMachineRootListController

setTimeMachine: libTimeMachine
	$(CC) -fobjc-arc -framework Foundation libTimeMachine.dylib setTimeMachine.m -o setTimeMachine
	strip setTimeMachine
	$(LDID) -Sentitlements-apfs.xml setTimeMachine

TimeMachine: libTimeMachine
	$(CC) -framework CoreFoundation libTimeMachine.dylib TimeMachine.c -o TimeMachine
	strip TimeMachine
	$(LDID) -Sentitlements-apfs.xml TimeMachine

clean:
	rm -rf $(Package)_* libTimeMachine.dylib postinst prerm TimeMachineRootListController snapshotcheck setTimeMachine TimeMachine
