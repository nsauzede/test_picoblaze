all:
	@echo "make what ? (update,open)"

update:
	make -C PicoBlaze clean all
	(cd working;../bitUpdate.bash ram_1024_x_18 aaatop.ncd ../PicoBlaze/rom.mem aaatop.bit; start download.bit)

open:
	start test_picoblaze.xise

clobber:
	make -C PicoBlaze clobber
	$(RM) *~
