TARGET = TimeMachine-on-iOS

.PHONY: all clean

all: TimeMachine TimeMachineLite

TimeMachine:
	dpkg -b com.michael.TimeMachine-*/

TimeMachineLite:
	dpkg -b com.michael.TimeMachineLite-*/

clean:
	rm -rf com.michael.TimeMachine-*.deb com.michael.TimeMachineLite-*.deb
