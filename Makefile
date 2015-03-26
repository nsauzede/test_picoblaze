all:
	@echo "make what ? (update,open)"

update:
	make -C PicoBlaze clean all
	./bitUpdate.bash ram_1024_x_18 working/aaatop.ncd PicoBlaze/rom.mem working/aaatop.bit
	start working/download.bit

open:
	start test_picoblaze.xise

clobber:
	make -C PicoBlaze clobber
	$(RM) *~
