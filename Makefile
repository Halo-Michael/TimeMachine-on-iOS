TARGET = TimeMachine-on-iOS
VERSION = 0.8.2
CC = xcrun -sdk iphoneos clang -arch arm64 -arch arm64e -miphoneos-version-min=10.3
LDID = ldid

.PHONY: all clean

all: clean postinst preinst prerm snapshotcheck setTimeMachine TimeMachine
	mkdir com.michael.TimeMachine-$(VERSION)_iphoneos-arm
	mkdir com.michael.TimeMachine-$(VERSION)_iphoneos-arm/DEBIAN
	cp control com.michael.TimeMachine-$(VERSION)_iphoneos-arm/DEBIAN
	mv postinst preinst prerm com.michael.TimeMachine-$(VERSION)_iphoneos-arm/DEBIAN
	mkdir com.michael.TimeMachine-$(VERSION)_iphoneos-arm/etc
	mkdir com.michael.TimeMachine-$(VERSION)_iphoneos-arm/etc/rc.d
	mv snapshotcheck com.michael.TimeMachine-$(VERSION)_iphoneos-arm/etc/rc.d
	mkdir com.michael.TimeMachine-$(VERSION)_iphoneos-arm/Library
	mkdir com.michael.TimeMachine-$(VERSION)_iphoneos-arm/Library/LaunchDaemons
	cp com.michael.TimeMachine.plist com.michael.TimeMachine-$(VERSION)_iphoneos-arm/Library/LaunchDaemons
	mkdir com.michael.TimeMachine-$(VERSION)_iphoneos-arm/usr
	mkdir com.michael.TimeMachine-$(VERSION)_iphoneos-arm/usr/bin
	mv setTimeMachine/.theos/obj/setTimeMachine com.michael.TimeMachine-$(VERSION)_iphoneos-arm/usr/bin
	mkdir -p com.michael.TimeMachine-$(VERSION)_iphoneos-arm/Library/PreferenceBundles
	mkdir -p com.michael.TimeMachine-$(VERSION)_iphoneos-arm/Library/PreferenceLoader/Preferences
	cp -av setTimeMachine/.theos/obj/TimeMachineiOS.bundle com.michael.TimeMachine-$(VERSION)_iphoneos-arm/Library/PreferenceBundles
	cp -av setTimeMachine/timemachineios/entry.plist com.michael.TimeMachine-$(VERSION)_iphoneos-arm/Library/PreferenceLoader/Preferences/TimeMachineiOS.plist
	mkdir com.michael.TimeMachine-$(VERSION)_iphoneos-arm/usr/libexec
	mv TimeMachine/.theos/obj/TimeMachine com.michael.TimeMachine-$(VERSION)_iphoneos-arm/usr/libexec
	dpkg -b com.michael.TimeMachine-$(VERSION)_iphoneos-arm

postinst: clean
	$(CC) postinst.c -o postinst
	strip postinst
	$(LDID) -Sentitlements.xml postinst

preinst: clean
	$(CC) preinst.c -o preinst -framework CoreFoundation
	strip preinst
	$(LDID) -Sentitlements-apfs.xml preinst

prerm: clean
	$(CC) prerm.c -o prerm -framework CoreFoundation
	strip prerm
	$(LDID) -Sentitlements-apfs.xml prerm

snapshotcheck: clean
	$(CC) snapshotcheck.c -o snapshotcheck -framework CoreFoundation
	strip snapshotcheck
	$(LDID) -Sentitlements-apfs.xml snapshotcheck

setTimeMachine: clean
	sh make-setTimeMachine.sh

TimeMachine: clean
	sh make-TimeMachine.sh

clean:
	rm -rf com.michael.TimeMachine-* postinst preinst prerm snapshotcheck setTimeMachine/.theos TimeMachine/.theos

install:
	scp com.michael.TimeMachine-$(VERSION)_iphoneos-arm.deb root@$(THEOS_DEVICE_IP):/tmp/_theos_install.deb
	ssh root@$(THEOS_DEVICE_IP) dpkg -i /tmp/_theos_install.deb
