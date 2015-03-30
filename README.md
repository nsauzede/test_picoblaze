# test_picoblaze
This is a test of Xilinx picoblaze 8-bit soft-core on the GadgetFactory papilio One fpga board

The top also instantiates a simple UART from Xilinx clocked at 3Mbps, and SPI master/slave IPs
The picoblaze firmware is a dead simple "monitor" that lets talking to the SPI master, to send
an 8-bit value to the SPI slave, that displays it on a ButtonLed wing

The PicoBlaze asm source is compiled with picoasm :
http://marksix.home.xs4all.nl/picoasm.html

The bitstream live update technique is based on :
http://www.labbookpages.co.uk/fpgas/picoBlaze.html
