TARGET = TimeMachine-on-iOS

.PHONY: all clean

all: TimeMachine TimeMachineLite

TimeMachine:
	dpkg -b com.michael.TimeMachine-0.3.1

TimeMachineLite:
	dpkg -b com.michael.TimeMachineLite-0.3.1

clean:
	rm -rf com.michael.TimeMachine-0.3.1.deb com.michael.TimeMachineLite-0.3.1.deb
