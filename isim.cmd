onerror {resume}
vcd dumpfile simu.vcd;
vcd dumpvars -m spi0;
vcd dumpon;
run 200 us;
vcd dumpoff;
vcd dumpflush;
