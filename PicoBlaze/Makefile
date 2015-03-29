TARGET=rom.vhd

all:$(TARGET)

rom.vhd:rom.psm ROM_form.vhd
	picoasm -i $< -t ROM_form.vhd
	@echo Assembled `cat rom.mem|grep -v @|grep -v 00000|wc -l` instructions out of 1024

clean:
	$(RM) $(TARGET)

clobber: clean
	$(RM) *~ rom.log rom.mem
