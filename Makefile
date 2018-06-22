TARGET = boards/kc705

all:
	cd $(TARGET) && make

program:
	cd $(TARGET) && make program

sim:
	cd $(TARGET) && make sim

clean:
	cd $(TARGET) && make clean
