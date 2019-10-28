TARGET = TimeMachine-on-iOS
VERSION = 0.6.3

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
	xcrun -sdk iphoneos clang -arch arm64 -Weverything postinst.c -o postinst -framework IOKit -O2
	ldid -Sentitlements.xml postinst

preinst: clean
	xcrun -sdk iphoneos clang -arch arm64 -Weverything preinst.c -o preinst -framework IOKit -O2
	ldid -Sentitlements-apfs.xml preinst

prerm: clean
	xcrun -sdk iphoneos clang -arch arm64 -Weverything prerm.c -o prerm -framework IOKit -O2
	ldid -Sentitlements-apfs.xml prerm

snapshotcheck: clean
	xcrun -sdk iphoneos clang -arch arm64 -Weverything snapshotcheck.c -o snapshotcheck -framework IOKit -O2
	ldid -Sentitlements-apfs.xml snapshotcheck

setTimeMachine: clean
	xcrun -sdk iphoneos clang -arch arm64 -Weverything setTimeMachine.c -o setTimeMachine -framework IOKit -O2
	ldid -Sentitlements-apfs.xml setTimeMachine

TimeMachine: clean
	xcrun -sdk iphoneos clang -arch arm64 -Weverything TimeMachine.c -o TimeMachine -framework IOKit -O2
	ldid -Sentitlements-apfs.xml TimeMachine

clean:
	rm -rf com.michael.TimeMachine-*
	rm -f postinst preinst prerm snapshotcheck setTimeMachine TimeMachine