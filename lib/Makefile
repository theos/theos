all: $(patsubst %.mm, %.o, $(wildcard *.mm))
clean:
	-rm -f *.o

%.o: %.mm
	arm-apple-darwin9-gcc -c $< -I ../include
