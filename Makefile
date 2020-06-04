TARGET = TimeMachine-on-iOS
VERSION = 0.9.0
CC = xcrun -sdk iphoneos clang -arch arm64 -arch arm64e -miphoneos-version-min=10.3
LDID = ldid

.PHONY: all clean

all: clean libTimeMachine postinst preinst prerm preferenceloader-bundle snapshotcheck setTimeMachine TimeMachine
	mkdir com.michael.TimeMachine_$(VERSION)_iphoneos-arm
	mkdir com.michael.TimeMachine_$(VERSION)_iphoneos-arm/DEBIAN
	cp control com.michael.TimeMachine_$(VERSION)_iphoneos-arm/DEBIAN
	mv postinst preinst prerm com.michael.TimeMachine_$(VERSION)_iphoneos-arm/DEBIAN
	mkdir com.michael.TimeMachine_$(VERSION)_iphoneos-arm/etc
	mkdir com.michael.TimeMachine_$(VERSION)_iphoneos-arm/etc/rc.d
	mv snapshotcheck com.michael.TimeMachine_$(VERSION)_iphoneos-arm/etc/rc.d
	mkdir com.michael.TimeMachine_$(VERSION)_iphoneos-arm/Library
	mkdir com.michael.TimeMachine_$(VERSION)_iphoneos-arm/Library/LaunchDaemons
	cp com.michael.TimeMachine.plist com.michael.TimeMachine_$(VERSION)_iphoneos-arm/Library/LaunchDaemons
	mkdir com.michael.TimeMachine_$(VERSION)_iphoneos-arm/usr
	mkdir com.michael.TimeMachine_$(VERSION)_iphoneos-arm/usr/bin
	mv setTimeMachine/.theos/obj/setTimeMachine com.michael.TimeMachine_$(VERSION)_iphoneos-arm/usr/bin
	mkdir com.michael.TimeMachine_$(VERSION)_iphoneos-arm/usr/lib
	mv libTimeMachine/.theos/obj/libTimeMachine.dylib com.michael.TimeMachine_$(VERSION)_iphoneos-arm/usr/lib
	mkdir com.michael.TimeMachine_$(VERSION)_iphoneos-arm/Library/PreferenceBundles
	mkdir com.michael.TimeMachine_$(VERSION)_iphoneos-arm/Library/PreferenceLoader
	mkdir com.michael.TimeMachine_$(VERSION)_iphoneos-arm/Library/PreferenceLoader/Preferences
	mv preferenceloader-bundle/.theos/obj/TimeMachine.bundle com.michael.TimeMachine_$(VERSION)_iphoneos-arm/Library/PreferenceBundles
	cp preferenceloader-bundle/entry.plist com.michael.TimeMachine_$(VERSION)_iphoneos-arm/Library/PreferenceLoader/Preferences/TimeMachine.plist
	mkdir com.michael.TimeMachine_$(VERSION)_iphoneos-arm/usr/libexec
	mv TimeMachine/.theos/obj/TimeMachine com.michael.TimeMachine_$(VERSION)_iphoneos-arm/usr/libexec
	dpkg -b com.michael.TimeMachine_$(VERSION)_iphoneos-arm

libTimeMachine: clean
	sh make-libTimeMachine.sh

postinst: clean
	$(CC) postinst.c -o postinst -framework CoreFoundation libTimeMachine.tbd
	strip postinst
	$(LDID) -Sentitlements.xml postinst

preinst: clean
	$(CC) preinst.c -o preinst -framework CoreFoundation libTimeMachine.tbd
	strip preinst
	$(LDID) -Sentitlements-apfs.xml preinst

prerm: clean
	$(CC) prerm.c -o prerm -framework CoreFoundation libTimeMachine.tbd
	strip prerm
	$(LDID) -Sentitlements-apfs.xml prerm

snapshotcheck: clean
	$(CC) snapshotcheck.c -o snapshotcheck -framework CoreFoundation libTimeMachine.tbd
	strip snapshotcheck
	$(LDID) -Sentitlements-apfs.xml snapshotcheck

preferenceloader-bundle: clean
	sh make-preferenceloader-bundle.sh

setTimeMachine: clean
	sh make-setTimeMachine.sh

TimeMachine: clean
	sh make-TimeMachine.sh

clean:
	rm -rf com.michael.TimeMachine_* libTimeMachine/.theos postinst preinst prerm preferenceloader-bundle/.theos snapshotcheck setTimeMachine/.theos TimeMachine/.theos

install:
	scp com.michael.TimeMachine_$(VERSION)_iphoneos-arm.deb root@$(THEOS_DEVICE_IP):/tmp/_theos_install.deb
	ssh root@$(THEOS_DEVICE_IP) dpkg -i /tmp/_theos_install.deb
