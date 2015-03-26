all:
	make -C PicoBlaze clean all
	./bitUpdate.bash ram_1024_x_18 working/aaatop.ncd PicoBlaze/rom.mem working/aaatop.bit
	start working/download.bit

clobber:
	$(RM) *~
