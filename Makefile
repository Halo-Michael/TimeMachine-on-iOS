export TARGET = iphone:clang:13.0:10.3
export ARCHS = arm64 arm64e
export VERSION = 0.10.8
export DEBUG = no
Package = com.michael.timemachine
CC = xcrun -sdk ${THEOS}/sdks/iPhoneOS13.0.sdk clang -arch arm64 -arch arm64e -miphoneos-version-min=10.3
LDID = ldid

.PHONY: all clean

all: clean libTimeMachine postinst prerm preferenceloader-bundle snapshotcheck setTimeMachine TimeMachine
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
	mv libTimeMachine/.theos/obj/libTimeMachine.dylib $(Package)_$(VERSION)_iphoneos-arm/usr/lib
	mkdir $(Package)_$(VERSION)_iphoneos-arm/Library/PreferenceBundles
	mkdir $(Package)_$(VERSION)_iphoneos-arm/Library/PreferenceLoader
	mkdir $(Package)_$(VERSION)_iphoneos-arm/Library/PreferenceLoader/Preferences
	mv preferenceloader-bundle/.theos/obj/TimeMachine.bundle $(Package)_$(VERSION)_iphoneos-arm/Library/PreferenceBundles
	cp preferenceloader-bundle/entry.plist $(Package)_$(VERSION)_iphoneos-arm/Library/PreferenceLoader/Preferences/TimeMachine.plist
	mkdir $(Package)_$(VERSION)_iphoneos-arm/usr/libexec
	mv TimeMachine $(Package)_$(VERSION)_iphoneos-arm/usr/libexec
	dpkg -b $(Package)_$(VERSION)_iphoneos-arm

libTimeMachine: clean
	cd libTimeMachine && make

postinst: libTimeMachine
	$(CC) -fobjc-arc postinst.m -o postinst -framework Foundation libTimeMachine/.theos/obj/libTimeMachine.dylib
	strip postinst
	$(LDID) -Sentitlements-apfs.xml postinst

prerm: libTimeMachine
	$(CC) prerm.c -o prerm -framework CoreFoundation libTimeMachine/.theos/obj/libTimeMachine.dylib
	strip prerm
	$(LDID) -Sentitlements-apfs.xml prerm

snapshotcheck: libTimeMachine
	$(CC) -fobjc-arc snapshotcheck.m -o snapshotcheck -framework Foundation libTimeMachine/.theos/obj/libTimeMachine.dylib
	strip snapshotcheck
	$(LDID) -Sentitlements-apfs.xml snapshotcheck

preferenceloader-bundle: libTimeMachine
	cd preferenceloader-bundle && make

setTimeMachine: libTimeMachine
	$(CC) -fobjc-arc setTimeMachine.m -o setTimeMachine -framework Foundation libTimeMachine/.theos/obj/libTimeMachine.dylib
	strip setTimeMachine
	$(LDID) -Sentitlements-apfs.xml setTimeMachine

TimeMachine: libTimeMachine
	$(CC) -fobjc-arc TimeMachine.m -o TimeMachine -framework Foundation libTimeMachine/.theos/obj/libTimeMachine.dylib
	strip TimeMachine
	$(LDID) -Sentitlements-apfs.xml TimeMachine

clean:
	rm -rf $(Package)_* libTimeMachine/.theos postinst prerm preferenceloader-bundle/.theos snapshotcheck setTimeMachine TimeMachine

install:
	scp $(Package)_$(VERSION)_iphoneos-arm.deb root@$(THEOS_DEVICE_IP):/tmp/_theos_install.deb
	ssh root@$(THEOS_DEVICE_IP) dpkg -i /tmp/_theos_install.deb
