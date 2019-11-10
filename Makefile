TARGET = TimeMachine-on-iOS
VERSION = 0.6.9
CC = xcrun -sdk iphoneos clang -arch arm64 -miphoneos-version-min=10.3
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
	mv setTimeMachine com.michael.TimeMachine-$(VERSION)_iphoneos-arm/usr/bin
	mkdir com.michael.TimeMachine-$(VERSION)_iphoneos-arm/usr/libexec
	mv TimeMachine com.michael.TimeMachine-$(VERSION)_iphoneos-arm/usr/libexec
	dpkg -b com.michael.TimeMachine-$(VERSION)_iphoneos-arm

postinst: clean
	$(CC) postinst.c -o postinst
	strip postinst
	$(LDID) -Sentitlements.xml postinst

preinst: clean
	$(CC) preinst.c -o preinst
	strip preinst
	$(LDID) -Sentitlements-apfs.xml preinst

prerm: clean
	$(CC) prerm.c -o prerm
	strip prerm
	$(LDID) -Sentitlements-apfs.xml prerm

snapshotcheck: clean
	$(CC) snapshotcheck.c -o snapshotcheck
	strip snapshotcheck
	$(LDID) -Sentitlements-apfs.xml snapshotcheck

setTimeMachine: clean
	$(CC) setTimeMachine.c -o setTimeMachine
	strip setTimeMachine
	$(LDID) -Sentitlements-apfs.xml setTimeMachine

TimeMachine: clean
	$(CC) TimeMachine.c -o TimeMachine
	strip TimeMachine
	$(LDID) -Sentitlements-apfs.xml TimeMachine

clean:
	rm -rf com.michael.TimeMachine-*
	rm -f postinst preinst prerm snapshotcheck setTimeMachine TimeMachine