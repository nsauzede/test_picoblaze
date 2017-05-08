all:
	@echo "make what ? (compile,update,open,clean,clobber)"

compile:
	make -C PicoBlaze clean all
update: compile
	(cd working;../bitUpdate.bash ram_1024_x_18 aaatop.ncd ../PicoBlaze/rom.mem aaatop.bit; papilio-prog -f download.bit)

open:
	start test_picoblaze.xise

prog: working/aaatop.bit
	papilio-prog -f $<

clean:
	make -C PicoBlaze clean

clobber:
	make -C PicoBlaze clobber
	$(RM) *~
