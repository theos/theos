%.o: %.mm
	$(CXX) -c $(CFLAGS) $< -o $@

%.o: %.m
	$(CXX) -c $(CFLAGS) $< -o $@
