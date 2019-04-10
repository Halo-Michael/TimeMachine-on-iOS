TARGET = TimeMachine-on-iOS

.PHONY: all clean

all: TimeMachine TimeMachineLite

TimeMachine:
	dpkg -b com.michael.TimeMachine-0.2.3

TimeMachineLite:
	dpkg -b com.michael.TimeMachineLite-0.2.3

clean:
	rm -rf com.michael.TimeMachine-0.2.3.deb com.michael.TimeMachineLite-0.2.3.deb
