TARGET = TimeMachine-on-iOS

.PHONY: all clean

all: TimeMachine TimeMachineLite

TimeMachine:
	dpkg -b com.michael.TimeMachine-0.3.2

TimeMachineLite:
	dpkg -b com.michael.TimeMachineLite-0.3.2

clean:
	rm -rf com.michael.TimeMachine-0.3.2.deb com.michael.TimeMachineLite-0.3.2.deb
